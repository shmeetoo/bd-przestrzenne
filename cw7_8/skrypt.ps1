# Automation of spatial data processing
# Created by Szymon Górny
# 15.12.2021


#https://mailtrap.io/blog/powershell-send-email/?fbclid=IwAR3HwVvxPQqcdtYkohKnv9D0QSOyKqRLXmR9_PiAf1YBsBStX9ukpezfFKQ

$dir = "D:\bazy_danych_przestrzennych\cw7_8\"
$url = "https://home.agh.edu.pl/~wsarlej/Customers_Nov2021.zip"
$INDEX = "402691"
$logFile = "${dir}PROCESSED\skrypt_${INDEX}.log"
$TIMESTAMP = Get-Date -Format "MM/dd/yyyy"
$customersTableName = "CUSTOMERS_${INDEX}"
$bestCustomersTableName = "BEST_CUSTOMERS_${INDEX}"

$user = "postgres"
$password = "admin"
$hostName = "localhost"
$port = "5432"
$database = "cw7_8"
$psql = "postgresql://${user}:${password}@${hostName}:${port}/${database}"
#$psql = 'postgresql://postgres:admin@localhost:5432/cw7_8'
Set-Location $dir


#download and unzip
Invoke-WebRequest -Uri $url -OutFile "${dir}Customers_Nov2021.zip"

$7zip = '"C:\Program Files\7-Zip\7z.exe"'
$zipPass = "agh"
$zipFile = '"${dir}Customers_Nov2021.zip"'

$command = "& $7zip e -o${dir} -y -tzip -p$zipPass $zipFile"
iex $command

if($?){
    Add-Content $logFile -Value "${TIMESTAMP} Unzip successful"
} else {
    Add-Content $logFile -Value "${TIMESTAMP} Unzip failed"
}


#csv import and validation
$customers = Import-Csv -Path "${dir}Customers_Nov2021.csv"
$customersOld = Import-Csv -Path "${dir}Customers_old.csv"

if($?){
    Add-Content $logFile -Value "${TIMESTAMP} CSV import successful"
} else {
    Add-Content $logFile -Value "${TIMESTAMP} CSV import failed"
}

$array = @()
$duplicates = 0
$tmp = 0

foreach($i in $customers){
    foreach($j in $customersOld){
        if($i.email -eq $j.email){
            $tmp = 1
            $duplicates += 1
            Add-Content "${dir}Customers_Nov2021.bad_${TIMESTAMP}.txt" $i

        }
    }
    if($tmp -eq 0){
        $array += $i
    }
    $tmp = 0
}

if($?){
    Add-Content $logFile -Value "${TIMESTAMP} Validation successful"
} else {
    Add-Content $logFile -Value "${TIMESTAMP} Validation failed"
}


#validated array export
$array | Export-Csv -Path "${dir}Customers_Nov2021.csv" -NoTypeInformation
Move-Item -Path "${dir}Customers_Nov2021.csv" -Destination "${dir}PROCESSED\${TIMESTAMP}_Customers_Nov2021.csv" -Force

if($?){
    Add-Content $logFile -Value "${TIMESTAMP} Validated data export successful"
} else {
    Add-Content $logFile -Value "${TIMESTAMP} Validated data export failed"
}

#database comfiguration - creating extension and table
"CREATE EXTENSION IF NOT EXISTS POSTGIS;" | psql $psql

if($?){
    Add-Content $logFile -Value "${TIMESTAMP} Postgis extension successful"
} else {
    Add-Content $logFile -Value "${TIMESTAMP} Postgis extension failed"
}

"DROP TABLE IF EXISTS $customersTableName; DROP TABLE IF EXISTS $bestCustomersTableName;" | psql $psql

"CREATE TABLE IF NOT EXISTS $customersTableName (first_name VARCHAR(100), last_name VARCHAR(100), email VARCHAR(100), geom GEOMETRY(POINT));" | psql $psql

if($?){
    Add-Content $logFile -Value "${TIMESTAMP} Table creation successful"
} else {
    Add-Content $logFile -Value "${TIMESTAMP} Table creation failed"
}


#insert into
foreach($customer in $array){
    $first_name = $customer.first_name
    $last_name = $customer.last_name
    $email = $customer.email
    $lat = $customer.lat
    $long = $customer.long

    "INSERT INTO $customersTableName VALUES ('${first_name}', '${last_name}', '${email}', ST_GeomFromText('POINT(${lat} ${long})',4326));" | psql $psql
}

if($?){
    Add-Content $logFile -Value "${TIMESTAMP} Table insert successful"
} else {
    Add-Content $logFile -Value "${TIMESTAMP} Table insert failed"
}

#email credentials
$credPassword = '7befb2dc06497e'
$securePassword = ConvertTo-SecureString $credPassword -AsPlainText -Force
$credUser = '4d139111abb196'
$cred = New-Object System.Management.Automation.PSCredential ($credUser, $securePassword)

#notification email
$correctRows = $array.Count # number of correct entries
$rows = $customers.Count #number of entries from the downloaded file
$tableInserts = $correctRows*4

$body = "Number of rows: ${rows} `nNumber of correct rows: ${correctRows} `nNumber of duplicates: ${duplicates} `nAmount of data inserted in the table: ${tableInserts}"

Send-MailMessage -To "jon-snow@winterfell.com" -From "mother-of-dragons@houseoftargaryen.net" -Subject "CUSTOMERS LOAD - ${TIMESTAMP}" -Body $body -Credential ($cred) -SmtpServer "smtp.mailtrap.io" -Port 587

if($?){
    Add-Content $logFile -Value "${TIMESTAMP} Mail sending successful"
} else {
    Add-Content $logFile -Value "${TIMESTAMP} Mail sending failed"
}

#sql query
"CREATE TABLE $bestCustomersTableName AS SELECT first_name, last_name, email, geom FROM $customersTableName x `
WHERE ST_DistanceSpheroid(x.geom, ST_GeomFromText('POINT(41.39988501005976 -75.67329768604034)',4326), 'SPHEROID[`"WGS 84`",6378137,298.257223563]')<50000" | psql $psql

if($?){
    Add-Content $logFile -Value "${TIMESTAMP} SQL query successful"
} else {
    Add-Content $logFile -Value "${TIMESTAMP} SQL query failed"
}

#export best_customers to csv and zip
"\copy $bestCustomersTableName to '$bestCustomersTableName.csv' csv header" | psql $psql

if($?){
    Add-Content $logFile -Value "${TIMESTAMP} Csv export successful"
} else {
    Add-Content $logFile -Value "${TIMESTAMP} Csv export failed"
}


$nCommand = "& $7zip a -mx=9 ${dir}${bestCustomersTableName}.zip ${dir}${bestCustomersTableName}.csv"
iex $nCommand


if($?){
    Add-Content $logFile -Value "${TIMESTAMP} Csv zip successful"
} else {
    Add-Content $logFile -Value "${TIMESTAMP} Csv zip failed"
}


#notification email with attachment
$lastMod = (Get-Item "${dir}${bestCustomersTableName}.csv").LastWriteTime
$nRows = (Import-Csv "${dir}${bestCustomersTableName}.csv" | Measure-Object).Count #number of entries
$nBody = "Last modification: ${lastMod} `nNumber of rows: ${nRows}"

Send-MailMessage -To "jon-snow@winterfell.com" -From "mother-of-dragons@houseoftargaryen.net" -Subject "BEST CUSTOMERS RAPORT" -Body $nBody -Attachments "${dir}${bestCustomersTableName}.zip" -Credential ($cred) -SmtpServer "smtp.mailtrap.io" -Port 587

