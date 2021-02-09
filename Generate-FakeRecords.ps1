<#
.SYNOPSIS
    Generates fake PII records
.DESCRIPTION
    Generates customizable set of fake PII records like ID, Name, SSN, Date of Birth, Email address.
.EXAMPLE
    PS C:\> Generate-FakeRecords.ps1
    Generate 10 fake user records with default fields: ID, Full Name, Social Security Number (SSN) 
.EXAMPLE
    PS C:\> Generate-FakeRecords.ps1 -OutputFile FakeRecords.csv -NumberofRecordsToGenerate 100 -SeparateFirstLastName
    Generates 100 fake user records with fields: ID, First Name, Last Name, Social Security Number (SSN) and saves them to CSV file FakeRecords.csv
.PARAMETER OutputFile
    Filename where output will be saved in CSV format. If no filename specified, generated records will be printed on the screen.
.PARAMETER NumberofRecordsToGenerate
    How many records should be generated. The default number is 10.
.PARAMETER SeparateFirstLastName
    Generated records will have separate First Name and Last Name fields. The default value is False - generated records have just one field Full Name.
#>
param (
    [Parameter(Mandatory=$false)]
        [string]$OutputFile = "",
    [Parameter(Mandatory=$false)]
        [int]$NumberofRecordsToGenerate = 10,
    [Parameter(Mandatory=$false)]
        [switch]$SeparateFirstLastName = $false,
    [Parameter(Mandatory=$false)]
        [switch]$IncludeID = $true,
    [Parameter(Mandatory=$false)]
        [switch]$IncludeSSN = $true,
    [Parameter(Mandatory=$false)]
        [switch]$IncludeDoB = $false,
    [Parameter(Mandatory=$false)]
        [switch]$IncludeEmail = $false,
    [Parameter(Mandatory=$false)]    
        [string]$EmailDomain = "contoso.com"
)

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function GenerateFirstName() {    
    # top100 most popular male and female names in 2020
    $FirstNames = @('James','John','Robert','Michael','William','David','Richard','Joseph','Thomas','Charles','Christopher','Daniel','Matthew','Anthony','Donald','Mark','Paul','Steven','Andrew','Kenneth','Joshua','Kevin','Brian','George','Edward','Ronald','Timothy','Jason','Jeffrey','Ryan','Jacob','Gary','Nicholas','Eric','Jonathan','Stephen','Larry','Justin','Scott','Brandon','Benjamin','Samuel','Frank','Gregory','Raymond','Alexander','Patrick','Jack','Dennis','Jerry','Tyler','Aaron','Jose','Henry','Adam','Douglas','Nathan','Peter','Zachary','Kyle','Walter','Harold','Jeremy','Ethan','Carl','Keith','Roger','Gerald','Christian','Terry','Sean','Arthur','Austin','Noah','Lawrence','Jesse','Joe','Bryan','Billy','Jordan','Albert','Dylan','Bruce','Willie','Gabriel','Alan','Juan','Logan','Wayne','Ralph','Roy','Eugene','Randy','Vincent','Russell','Louis','Philip','Bobby','Johnny','Bradley','Mary','Patricia','Jennifer','Linda','Elizabeth','Barbara','Susan','Jessica','Sarah','Karen','Nancy','Lisa','Margaret','Betty','Sandra','Ashley','Dorothy','Kimberly','Emily','Donna','Michelle','Carol','Amanda','Melissa','Deborah','Stephanie','Rebecca','Laura','Sharon','Cynthia','Kathleen','Amy','Shirley','Angela','Helen','Anna','Brenda','Pamela','Nicole','Samantha','Katherine','Emma','Ruth','Christine','Catherine','Debra','Rachel','Carolyn','Janet','Virginia','Maria','Heather','Diane','Julie','Joyce','Victoria','Kelly','Christina','Lauren','Joan','Evelyn','Olivia','Judith','Megan','Cheryl','Martha','Andrea','Frances','Hannah','Jacqueline','Ann','Gloria','Jean','Kathryn','Alice','Teresa','Sara','Janice','Doris','Madison','Julia','Grace','Judy','Abigail','Marie','Denise','Beverly','Amber','Theresa','Marilyn','Danielle','Diana','Brittany','Natalie','Sophia','Rose','Isabella','Alexis','Kayla','Charlotte')    
    return $FirstNames[(Get-Random -Minimum 0 -Maximum ($FirstNames.Count-1))]
}

function GenerateLastName() {
    # top100 most popular last names in 2020
    $LastNames = @('Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez','Hernandez','Lopez','Gonzales','Wilson','Anderson','Thomas','Taylor','Moore','Jackson','Martin','Lee','Perez','Thompson','White','Harris','Sanchez','Clark','Ramirez','Lewis','Robinson','Walker','Young','Allen','King','Wright','Scott','Torres','Nguyen','Hill','Flores','Green','Adams','Nelson','Baker','Hall','Rivera','Campbell','Mitchell','Carter','Roberts','Gomez','Phillips','Evans','Turner','Diaz','Parker','Cruz','Edwards','Collins','Reyes','Stewart','Morris','Morales','Murphy','Cook','Rogers','Gutierrez','Ortiz','Morgan','Cooper','Peterson','Bailey','Reed','Kelly','Howard','Ramos','Kim','Cox','Ward','Richardson','Watson','Brooks','Chavez','Wood','James','Bennet','Gray','Mendoza','Ruiz','Hughes','Price','Alvarez','Castillo','Sanders','Patel','Myers','Long','Ross','Foster','Jimenez')
    return $LastNames[(Get-Random -Minimum 0 -Maximum ($LastNames.Count-1))]
}

function GenerateFullName() {    
    return (GenerateFirstName)  + " " + (GenerateLastName)
}

function GenerateID() {
    # char 65-90 = A-Z
    $prefix = ""
    for ($i = 0; $i -lt 3; $i++) {
        $prefix = $prefix + [char](Get-Random -Minimum 65 -Maximum 90)
    }    
    $number = Get-Random -Minimum 100000 -Maximum 999999
    return $prefix + "-" + $number
}

function GenerateDOB() {    
    $m = Get-Random -Minimum 1 -Maximum 12
    $d = Get-Random -Minimum 1 -Maximum 28          # i'm too lazy to implement Feb 30-31 checks :)
    $y = Get-Random -Minimum 1920 -Maximum 2020
    return "$m/$d/$y"
}

function GenerateSSN() {
    [string]$ssn = ""
    for ($i = 1; $i -lt 10; $i++) {
        [string]$n = (Get-Random -Minimum 0 -Maximum 9).ToString()
        if (($i -eq 4) -or ($i -eq 6)) {
            $ssn = $ssn + "-" + $n
        } else {
            $ssn = $ssn + $n
        }                
    }
    if (!($ssn -match '(?!666|000)[0-8][0-9]{2}-(?!00)[0-9]{2}-(?!0000)[0-9]{4}')) {    # simple regex to validate SSN eg no 666 or 000 etc 
        $ssn = GenerateSSN
    } 
    return $ssn
}

function GenerateEmail ($FirstName, $LastName, $EmailDomain) {
    return "$FirstName.$LastName@$EmailDomain"
}

function GenerateHeader($OutputFile, $separateFirstLastName, $includeSSN, $includeDoB, $includeEmail, $EmailDomain) {    
    $header = ""    

    # Name 
    if ($separateFirstLastName -ne $true) {
        $header = $header + "Full Name"
    }
    else {
        $header = $header + "First Name,Last Name"
    }    

    # SSN
    if($includeSSN) {
        $header = $header + ",SSN"
    }

    # Date of Birth
    if ($includeDoB) {
        $header = $header + ",Date of Birth"
    }

    # Email
    if ($includeEmail) {
        $header = $header + ",Email"
    }

    # ID
    if ($includeID) {
        $header = "ID," + $header
    }

    if ($OutputFile -ne "") {
        $header | Out-File -FilePath $OutputFile
    }   

    return $header
}

function GenerateRecord($separateFirstLastName, $includeSSN, $includeDoB, $includeEmail, $EmailDomain) {
    $record = ""
    $name = "";
    
    # Name section
    if ($separateFirstLastName -ne $true) {
        $record = (GenerateFullName)
        $name = $record.Split(" ")
    }
    else {
        $record = (GenerateFirstName) + "," + (GenerateLastName)
        $name = $record.Split(",")
    }

    # SSN
    if($includeSSN) {
        $record = $record + "," + (GenerateSSN)
    }

    # Date of Birth
    if ($includeDoB) {
        $record = $record + "," + (GenerateDOB)
    }

    # Email
    if ($includeEmail) {
        $record = $record + "," + (GenerateEmail $name[0] $name[1] $EmailDomain)
    }

    #ID
    if ($includeID) {
        $record = (GenerateID) + "," + $record
    }

    return $record
}    

#-----------------------------------------------------------[Execution]------------------------------------------------------------

GenerateHeader $OutputFile $separateFirstLastName $includeSSN $includeDoB $includeEmail $EmailDomain

for ($i = 1; $i -le $NumberofRecordsToGenerate; $i++)
{
    $record = GenerateRecord $separateFirstLastName $includeSSN $includeDoB $includeEmail $EmailDomain

    if ($OutputFile -ne "") {
        $record | Out-File -FilePath $OutputFile -NoClobber -Append
    }
    $record    
}
