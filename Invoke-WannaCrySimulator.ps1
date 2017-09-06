<#

.Synopsis

    Windows bilgisayarları Active Directory üzerinden tespit ederek bağlanmayı dener ve WannaCry bağlantılı hotfixlerin varlığını kontrol eder. Tespit edilen ve kontrol edilen bilgisayarlar hakkındaki rapor kullanıcının “MyDocuments” klasörü altına kaydedilir.

.DESCRIPTION

   Script active directory içerisinde MS17-010 zafiyeti içeren bilgisayarları tespit etmektedir. Eğer bir bilgisayar script çalıştığı sırada kapalı ya da erişilemez ise ilgili bilgisayar kontrol edilmemektedir.
   
.EXAMPLE

   Invoke-WannaCrySimulator
   
#>

#Parametreler

$Patchliler = @()
$Patchsizler = @()
$KontrolEdilemeyenler = @()
$KapaliBilgisayarlar = @()

#Rapor

$rapor = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath "$($ENV:USERDOMAIN)_WannaCry_Patch_Raporu.log"

#Hotfixler

$HotfixID = @('KB4012212', 'KB4012213', 'KB4012214', 'KB4012215', 'KB4012216', 'KB4012217', 'KB4012598', 'KB4013429', 'KB4015217', 'KB4015438', 'KB4015549', 'KB4015550', 'KB4015551', 'KB4015552', 'KB4015553', 'KB4016635', 'KB4019215', 'KB4019216', 'KB4019264', 'KB4019472')

#Active directoryde bulunan Windows bilgisayarların tespiti

$WindowsBilgisayarlar = (Get-ADComputer -Filter {
    (OperatingSystem  -Like 'Windows*') -and (OperatingSystem -notlike '*Windows 10*')
}).Name |Sort-Object

"$(Get-Date -Format 'dd-MM-yyyy HH:mm') itibariyle WannaCry patch durumu" |Out-File -FilePath $rapor

#Bağlantı ve patch kontrol

$PCSayisi = $WindowsBilgisayarlar.count

"Active Directory bünyesinde $PCSayisi bilgisayar bulundu"

$i = 0

foreach($Bilgisayar in $WindowsBilgisayarlar) {

    $PatchliBilgisayarlar = @()
    $i++

    try {
    
        $baglantikontrol = Test-Connection -ComputerName $Bilgisayar -Count 1 -ErrorAction Stop
        
        try {
        
            $Hotfixler = Get-HotFix -ComputerName $Bilgisayar -ErrorAction Stop
            $HotfixID | ForEach-Object -Process { if($Hotfixler.HotFixID -contains $_) { $PatchliBilgisayarlar += $_ } }
            
        } catch {
        
            $KontrolEdilemeyenler += $Bilgisayar
            "***`t$Bilgisayar `tiçin hotfix bilgisi elde edilemedi" |Out-File -FilePath $rapor -Append
            continue
            
        }
        
        If($PatchliBilgisayarlar) {
        
          "$Bilgisayar patchli $($PatchliBilgisayarlar -join (','))" |Out-File -FilePath $rapor -Append
          $Patchliler += $Bilgisayar
          
        }
        
        Else {
        
          $Patchsizler += $Bilgisayar
          "*****`t$Bilgisayar PATCHSİZ! *****" |Out-File -FilePath $rapor -Append
        }
        
    } catch {
    
        $KapaliBilgisayarlar += $Bilgisayar
        "****`t$Bilgisayar `tkapalı" |Out-File -FilePath $rapor -Append
      
      }
}

#Özet Rapor

' '
"$ENV:USERDNSDOMAIN domaini için özet"

"Patchsizler ($($Patchsizler.count)):" |Out-File -FilePath $rapor -Append 

$Patchsizler -join (', ')  |Out-File -FilePath $rapor -Append
'' |Out-File -FilePath $rapor -Append

"Patchliler ($($Patchliler.count)):" |Out-File -FilePath $rapor -Append 

$Patchliler -join (', ') |Out-File -FilePath $rapor -Append
'' |Out-File -FilePath $rapor -Append

"Test Edilemeyenler ($(($KapaliBilgisayarlar + $KontrolEdilemeyenler).count)):"|Out-File -FilePath $rapor -Append

($KapaliBilgisayarlar + $KontrolEdilemeyenler | Sort-Object)-join (', ')|Out-File -FilePath $rapor -Append

"Active directory içerisindeki $($WindowsBilgisayarlar.count) windows bilgisayar içinde, $($KapaliBilgisayarlar.count) kapalı bilgisayar, $($KontrolEdilemeyenler.count) kontrol edilemeyen bilgisayar, $($Patchsiz.count) patchsiz bilgisayar ve $($Patchli.count) patchli bilgisayar tespit edilmiştir."

'Detaylı rapor log dosyasındadır.'

try {
  Start-Process -FilePath notepad++ -ArgumentList $rapor
} catch {
  Start-Process -FilePath notepad.exe -ArgumentList $rapor
}