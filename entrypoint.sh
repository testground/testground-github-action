#!/usr/bin/env sh

PLANSHOME="${HOME}/testground/plans"

# exit codes determine the result of the CheckRun
# https://docs.github.com/en/actions/creating-actions/setting-exit-codes-for-actions
SUCCESS=0
FAILURE=1

# For github to collect the action output, use these strings:
OUTPUT_STATUS="::set-output name=status::"
OUTPUT_OUTCOME="::set-output name=outcome::"

BACKEND="${INPUT_BACKEND_PROTO}"'://'"${INPUT_BACKEND_ADDR}"

# Make sure the input files exist.
test -d "${INPUT_PLAN_DIRECTORY}" || exit "${FALURE}"
test -f "${INPUT_COMPOSITION_FILE}" || exit "${FAILURE}"

REAL_PLAN_DIR=$(realpath $INPUT_PLAN_DIRECTORY)
REAL_COMP_FILE=$(realpath $INPUT_COMPOSITION_FILE)

# link plan to testground home
mkdir -p "${PLANSHOME}"
ln -s "${REAL_PLAN_DIR}" "${PLANSHOME}"

echo real quick ls
ls -l "${PLANSHOME}"

# Run test and wait until finished.
# There is a --wait option, so it might work to use it like this
# testground --endpoint "$BACKEND" run composition -f "$REAL_COMP_FILE" --wait
# However, --wait doesn't always work well particularly for long-running jobs
# so instead, do a long poll.
/testground --endpoint "${BACKEND}" run composition -f "${REAL_COMP_FILE}" | tee testground.out
TGID=$(awk '/run is queued with ID/ {print $10}' <testground.out)

echo "Got testground ID ${TGID}"
echo "Waiting for job to complete."

while [ "${status}" != "complete" ]
do
	sleep 30
	status=$(/testground --endpoint "${BACKEND}" status -t "${TGID}" | awk '/Status/ {print $2}')
	echo "last polled status is ${status}"
	echo "${OUTPUT_STATUS}${status}"
done

echo getting extended status
/testground --endpoint "${BACKEND}" status -t "${TGID}" --extended  | tee extendedstatus.out
# Get the extened status, which includes a "Result" section.
# Capture the line that occurs after "Result"
extstatus=$(awk '/Result/ {getline; print $0}' <extendedstatus.out)

# First off, there are control characters in this output, and we need to remove that.
extstatus=$(echo "${extstatus}" | tr -d "[:cntrl:]" |  sed 's/\[0m //g')

# test if we got a result at all. The result might be "null". A null result means most likely the
# job was canceled before it began for some reason.
if [ "${extstatus}" == "null" ]
then
	echo "${OUTPUT_OUTCOME}failure/canceled"
	exit "$FAILURE"
fi

# Now find the outcome of the test. The extended result is going to look something like this:
# {"journal":{"events":{},"pods_statuses":{}},"outcome":"success","outcomes":{"providers":{"ok":1,"total":1},"requestors":{"ok":1,"total":1}}}

outcome=$(echo "${extstatus}" | jq ".outcome")

echo "the extended status was ${extstatus}"
echo "The outcome of this test was ${outcome}"
echo "${OUTPUT_OUTCOME}${outcome}"

test "${outcome}" = "\"success\"" && exit "${SUCCESS}" || exit "${FAILURE}"
