#!/usr/bin/env bash

set -e

# install rsync
apt-get update && apt-get install -y rsync && rm -rf /var/lib/apt/lists/*

# wait until port 873 is open on the host "old"
while ! nc -z old 873; do
  echo "Waiting for rsync daemon on old to start..."
  sleep 1
done

# Use rsync to figure out what changes are necessary to go from old image contents to new
echo "List of changes necessary to go from old image contents to new: "
rsync -a -x --no-times --human-readable --delete-after --checksum --dry-run --itemize-changes --exclude .docker-image-diff "$RESTRICT_DIFF_TO_PATH/" "rsync://rsync@old/root$RESTRICT_DIFF_TO_PATH/" | tee $OUT/changes.rsync.log

# Add files to add to a tar archive
cat $OUT/changes.rsync.log | grep  -E '^<f|^cL|^hf' | while read -a cols; do echo "$RESTRICT_DIFF_TO_PATH/"${cols[@]:1}; done > $OUT/files-to-add_2.list

# soft links (^cL in the grep above) have -> in the list which must be removed.  Hard links ^hf have =>
cat $OUT/files-to-add_2.list | grep -oP '^\K.*?(?= ->| =>|$)' > $OUT/files-to-add.list
tar -C / -cf $OUT/files-to-add.tar -T $OUT/files-to-add.list 2>&1

# Add files to remove to a list
cat $OUT/changes.rsync.log | grep '^*deleting' | grep -v 'tmp\/\.rsyncd\.conf' | while read -a cols; do echo "$RESTRICT_DIFF_TO_PATH/"${cols[@]:1}; done > $OUT/files-to-remove.list

# Informational output
echo
echo "Number of files to add: "
wc -l $OUT/files-to-add.list
echo
echo "Number of files to remove: "
wc -l $OUT/files-to-remove.list
echo
echo "Changes not accounted for: "
cat $OUT/changes.rsync.log | grep -v -E '^<f|^cL|^hf|^cd'  | grep -v '^*deleting' || [[ $? == 1 ]] && echo "None"
echo
echo "Finished generating changes."
echo "Set finished-generating marker file."
echo "Press CTRL-C to continue if not automatically continuing."

touch $OUT/.finished-generating
