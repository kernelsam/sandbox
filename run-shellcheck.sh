echo "[INFO] shellcheck version: $(shellcheck --version)"

declare -i status=0
for file in $(find . -type f -name "*.sh"); 
  do shellcheck --format=gcc $file;
  status+=$?
done;

echo "[INFO] Exit status is: ${status}"
exit ${status}