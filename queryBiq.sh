#/bin/bash

usage="$(basename "$0") --apiUrl=URL_TO_EVENTS_SERVICE --start=START_TIME_IN_UNIX_MS --end=END_TIME_IN_UNIX_MS --account=GLOBAL_CUSTOMER_NAME --apiKey=ANALYTICS_API_KEY --query=QUERY_TO_RUN_IN_QUOTES --file=OUTPUT_FILE_NAME"
example="$(basename "$0") --apiUrl=analytics.api.appdynamics.com --start=1503256982000 --end=1503343383000 --account=customer1_12345-6789-abc-def --apiKey=123456-zyx-987-456-0c8ea754be53 --query=\"SELECT \* FROM transactions\" --file=/foo/bar/output.txt"

# Evaulate options
while :; do
    case $1 in
        -h|-\?|--help)
        echo $usage
	echo $example
        exit
        ;;
    --apiUrl=?*)
        apiUrl=${1#*=}
        ;;
    --start=?*)
        start=${1#*=}
        ;;
    --end=?*)
        end=${1#*=}
        ;;
    --account=?*)
        account=${1#*=}
        ;;
    --apiKey=?*)
        apiKey=${1#*=}
        ;;
    --query=?*)
        query=${1#*=}
        ;;
    --file=?*)
	file=${1#*=} 
	;;
    --)
        shift
        break
        ;;
    -?*)
        printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
        ;;
    *)
        break
    esac
    shift
done

# Check initial size of query
# Assumes a SELECT xxx FROM statement with COUNT already in place
# You really shouldn't be using this script for COUNT queries...
function checkSize () {
    echo "In checkSize()"

    countsub=${query#* FROM}
    countQuery="SELECT count(*) FROM $countsub"

    if echo $countQuery | grep -i "order by"; then
	    countQuery=${countQuery%ORDER BY*}
    fi

    echo "Count Query = $countQuery"

    countString=`/usr/bin/curl -X POST "http://${apiUrl}/events/query?start=${start}&end=${end}&limit=${limit}" -H"X-Events-API-AccountName:${account}" -H"X-Events-API-Key:${apiKey}" -H"Content-type: application/vnd.appd.events+text;v=2" -d "${countQuery}"`

    echo $countString
    sub=${countString#*results\":[[}
    count=${sub%]]*}
    echo "Query count is $count"
}

# Execute chunked queries
function runLoops () {
    echo "In runloops - running $loops loops"
    outfile=$1

    while [ $loops -gt 0 ]; do
	    end=$((start+timeIncrement))
	    echo "Running loop $loops"
      runQuery $outfile
      start=$((start+timeIncrement))
      loops=$[$loops-1]
    done

    echo "Loops complete"
}

function runQuery () {
    echo "Running Query with Start = $start and End = $end"
    outfile=$1

    /usr/bin/curl -X POST "http://${apiUrl}/events/query?start=${start}&end=${end}&limit=${limit}" -H"X-Events-API-AccountName:${account}" -H"X-Events-API-Key:${apiKey}" -H"Content-type: application/vnd.appd.events+text;v=2" -d "${query}" >> $outfile

}
##############################################
#################### MAIN ####################
##############################################
divisor=5000
excelMax=65000
checkSize

# Ensure output file is empty before starting
rm $file

# If size is greater than divisor (default=5000), we'll iterate using loops of divisor amounts
# Divisor amount is less than max to ensure that equally spliting the time ranges won't miss transactions when spikes occur
if [[ $count -gt $divisor ]]; then
    loops=$((count/$divisor))
    echo "Need to chunk results - running $loops loops"

    # Calculate delta between start and end and divide by loops value
    delta=$((end-start))
    timeIncrement=$((delta/loops))
    echo "Time Increment = $timeIncrement"

    # Max number of rows in an Excel file is 65,535
    # For easy viewing in Excel, we'll break large sets into multiple files
    if [[ $count -gt $excelMax ]]; then
        echo "Count is greater then max Excel file size - will output to multiple files"
        fileLoops=$((count/excelMax))
        queryLoopsByFile=$((loops/fileLoops))
        queryLoopsRemainder=$((loops%fileLoops))
        echo "File loops = $fileLoops"

        while [ $fileLoops -gt 0 ]; do
          # Setting query loops to number of loops per file
          echo "In File Loop $fileLoops - using $queryLoopsByFile loops per file"
          fileNameByLoop=$file.$start

          echo "Using file $fileNameByLoop"
          loops=$queryLoopsByFile
          runLoops $fileNameByLoop

          fileLoops=$[$fileLoops-1]
        done

        # If there's a mod value in the loop, make sure to run them as well
        if [[ $queryLoopsRemainder -ne 0 ]]; then
            fileNameByLoop=$file.$start
            echo "Running remainder loops of $queryLoopsRemainder"
            echo "Using file $fileNameByLoop"
            loops=$queryLoopsRemainder
            runLoops $fileNameByLoop
        fi

    echo "Completed file loop"
    else
	      echo "No need for file loop"
        runLoops $file
    fi

else
    echo "Query size is under $divisor - no need to run chunk"
    runQuery $file
fi

# Execute Groovy script to convert timestamps and prettify for CSV
# Not yet implemented
echo "Run Groovy script for timestamp conversion and CSV conversion"
