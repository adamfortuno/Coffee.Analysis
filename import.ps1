## Run this script at the parent folder for a test series.

## Process Detail Records
$files_detail = Get-ChildItem -Path . -Recurse -Filter test_detail_*.csv
foreach ($file in $files_detail) {
	$content = Get-Content $file.Fullname -ReadCount 0
	$content = $content -replace '"', ''
	Add-Content .\details.csv -Value $($content[1..$($content.length -1)])
}
bcp.exe "ae_analysis.dbo.detail" in "details.csv" -S"(local)" -T -k -c -q -t"\t" -h "tablock" -e details.err -b 250000
Remove-Item -Path .\details.csv, .\details.err

## Process Summary Records
$files_detail = Get-ChildItem -Path . -Recurse -Filter test_summary_*.csv
foreach ($file in $files_detail) {
	$test, $cycle = $($file.directoryname | Split-Path -Leaf).Split('-')
	$updates = @()
	$content = Get-Content $file.Fullname -ReadCount 0
	$content = $content -replace '"', ''
	foreach ($line in $content[1..$($content.length -1)]) {
		$updates += "{0}`t{1}`t{2}" -f $test, $cycle, $line
	}
	Add-Content .\summary.csv -Value $updates
}
bcp.exe "ae_analysis.dbo.summary" in "summary.csv" -S"(local)" -T -k -c -q -t"\t" -h "tablock" -e summary.err -b 20
Remove-Item -Path .\summary.csv, .\summary.err