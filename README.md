# bizIQ.chunkedQueries
Script for querying large sets of BizIQ Data

The BizIQ GUI interfaces limits queries to 1000 results. For use cases where more records need to be exported, this script will disseminate the given query and time range to smaller queries and recursively call them, building a single file with all results (with a few caveats). For extremely large queries (results > 65,000 records), multiple files will be created with the start timestamp of the first query in that file appended to the passed file name.

Eventually, this script will also have the option to change the output to CSV and "prettify" the timestamps. Still a work in progress.


KNOWN LIMITATIONS: Right now, the script will return header values from the query multiple times in each file. This can be easily dealt with by hand by removing those headers but I haven't had time to make the necessary updates.

The script takes several arguments (all required):

--apiUrl = URL to the Events Service (analytics.api.appdynamics.com if on SaaS). Do not include the protocol (HTTP://), port number or any subsequent values

--start = Start timestamp in Epoch milliseconds

--end = End timestamp in Epoch milliseconds

--account = Global account name for customer

--apiKey = API Key for accessing the REST API of the customer (see this documentation for further information)

--query = Full query, in single quotes

--file = Output file name


Example Usage:

queryBiq.sh --apiUrl=analytics.api.appdynamics.com --start=1503256982000 --end=1503343383000 --account=customer1_12345-6789-abc-def --apiKey=123456-zyx-987-456-0c8ea754be53 --query="SELECT \* FROM transactions" --file=/foo/bar/output.txt
