## Info

This archive contains developer/debug-signed titles for the following Nintendo systems:

| System | Titles | Versions | On Retail CDN | Has Google Results | Size      |
| ------ | ------ | -------- | ------------- | ------------------ | --------- |
| Wii    | 653    | 1,660    | 1,489         | 1,438              | 1.63 TB   |
| DSi    | 153    | 188      | 138           | 174                | 1.01 GB   |
| 3DS    | 4,689  | 12,373   | N/A           | 9,219              | 279.48 GB |
| Wii U  | 2,413  | 7,000    | 2,084         | 6,446              | 1.02 TB   |
| vWii   | 44     | 101      | 73            | 101                | 1.6 GB    |
| Total  | 7,952  | 21,322   | 3,784         | 17,378             | 2.93 TB   |

This data came from an instance of Nintendo's developer CDN, which remained online and publically accessible until September 2024. The security mechanisms backported onto the 3DS CDN from the Switch CDN are not present on this developer CDN, meaning all content (including 3DS content) was accessible. The CDN seems to lack Nintendo Switch titles, though this is to be expected.

Each title that was found has all available versions archived. Tickets are only provided for titles which have legitimate `cetk` tickets, no tickets were generated. The title keys inside these tickets are encrypted with the systems developer key(s). For the DSi, Wii, and Wii U see https://wiki.wiidatabase.de/wiki/Common-Key.

Only the encrypted title contents, TMD, ticket (if available), and metadata is provided. No decrypted contents or source code is available.

While the titles are not signed with retail keys, some titles may be retail builds simply signed with different keys. Whether or not a title is a retail build must be determined on a case-by-case basis. This archive contains developer tools and unreleased title versions not available on the retail CDNs, however there are cases where there are no visible differences between a title found in this archive and a retail build (besides the keys/signatures).

The 3DS and vWii systems will have some overlap with the DSi and Wii systems respectively. https://wiibrew.org/wiki/Title_database also documents some titles as being vWii and Wii Mini exclusive, however they share title IDs with other Wii content. It is not known which version of these shared title IDs is present on the CDN.

## CDN closure

In the past the CDN has been unstable and had errors (mostly 5XX, likely due to overload), and even went down entirely (also likely due to overload), however these always resolved after some time. The CDN would come back online following general Nintendo maintenance (this could be tracked using Nintendo's maintenance announcements). However at some point in September 2024 Nintendo seems to have done some upgrades to the CDN. Any 5XX errors or server crashes seemed to automatically recover after a short while.

The CDN is now (seemingly) permanently closed. At some point on Thursday September 26th, 2024, Nintendo seemed to have finally noticed the traffic and now block it. They implemented [BigIP](https://www.f5.com/products/big-ip) in front of the CDN, which provides ACLs to manage data access. Following this update ***ALL*** requests to the CDN will always return the following HTTP response, regardless of things like request path:

```
HTTP/1.0 403 Forbidden
Server: BigIP
Connection: close
Content-Length: 131


     <html>
     <head><title>HTTP Request denied</title></head>
     <body>Your HTTP requests was denied.</body>
     </html>
   
```

This is the first time the server has started sending 4XX responses, despite being scanned for over a year. This likely means this is an intentional act by Nintendo in response to these scans. Despite the name, this is not an IP *ban*. Attempts were made from various IP addresses/servers in various countries and none were allowed access. Mimicking the exact conditions of a Wii U also proved ineffective. Nintendo likely restricted access to some internal IP list, or even set no conditions at all to simply block all access from anyone (there is no reason for anyone, even developers, to access this data anymore).

## Title scanning

This archive contains all known titles on the CDN, though the scanning process is imperfect. There are likely more undiscovered titles. Most title IDs came from existing lists of known titles across the internet, which will be linked in their respective sections. The 3DS and Wii U had larger scans done, outside of the known title IDs. These additional scans revealed some previously undocumented titles and unreleased title versions, including developer tools and debug/sample applications. These larger scans were not done for the other systems, meaning there could be other titles still missing from this archive.

The details of *all* unreleased/undocumented titles are not provided, as the archive has not been combed through, though each console section may list notable titles. Check the metadata for title IDs and compare them to known lists for a full breakdown.

Not all retail titles, or version updates, exist on the CDN. There will be missing titles/versions.

All systems had multiple scanning sessions. These include:

- "Initial" scan. This scan is done using lists of known title IDs, taken from various sources. This scan happens for all systems.
- "Range" scans. This scan does not use known title IDs, and instead brute forces through a predefined range of title IDs. This finds titles not found in public lists. Not all systems have this scan.
- "Mutation" scans. This scan takes title IDs which are known to exist on the CDN based on previous scans, and mutates the title IDs into ones not in public lists. This is done to find other variations of titles, such as updates or DLC, which may not be in public lists. Not all systems have this scan.
- "Version" scan. This scan goes through all known titles to find its latest version. All versions from v0 to the latest are then checked and downloaded. This scan happens for all systems, and all titles.

These scans combined are used to find all available titles and versions on the CDN, even those not currently documented/released. It is not possible to reasonably search the entire title ID range, as that would require searching the entire 64-bit number space. As such, some compromises had to be made which may have resulted in some titles not being found by this archive.

Following all title scans, a final "verification" scan is performed. This scan manually walks all downloaded titles, reads the TMD, and verifies that each content file was downloaded correctly. If any contents were missing or not the expected size, that content file is redownloaded, to ensure the dump is valid.

## Title metadata

Provided is a `titles.sqlite` database containing all currently known metadata about each title version. This includes the system, title type, name translations, title key, title key password, etc. Not every row will have data in each column, as not all data can be obtained for all titles.

The column `on_retail_cdn` indicates whether a title/version exists on the retail CDN. This was checked for all titles besides the 3DS, as they are not accessible freely on the retail CDN any longer making it impossible to check. `http://ccs.cdn.wup.shop.nintendo.net` is the retail CDN checked against.

The column `has_google_results` indicates whether or not the title has any results on Google searches. This can be useful for roughly determining if a title is documented or not. However it only indicates if *any* Google results are returned for the query, not what the search results actually are. There may be false positives/negatives. The results came from https://apify.com/apify/google-search-scraper by searching for each title ID as an uppercase string with no hyphen. Some results may be skewed, as some public lists may document title IDs as containing a hyphen. These results should not be the end-all-be-all of whether a title is documented or not, it should only serve as a brief overview and starting point.

## Extended title metadata

The Wii U and 3DS have extended metadata in the database. The Wii, DSi, and vWii lack this extended metadata, as the title contents were not scanned.

The Wii U had all extended metadata taken from the `meta.xml` file of the title, if it exists. A scan was done on each titles FSTs to locate the content file containing `./meta.xml`, which was then decrypted on the fly and the XML contents parsed from the binary using the regex `<menu.*?>.*?</menu>`. Due to potential issues with both the crypto (as it was hand-rolled) and the regex, not all Wii U titles may have all extended metadata even if the title key is known.

The 3DS had all extended metadata taken from it's main NCCH/SMDH. The tool https://github.com/ihaveamac/pyctr was used to locate the first title contents which contained `ncch.exefs.icon` (the title SMDH), which was assumed to be the "main" content. This assumption may be incorrect in some cases.

## Title keys

The title keys found in the database were calculated from the titles content files using the title key generation algorithm, not taken from tickets (even if a ticket exists). Because of this not all titles have known title keys, due to the password used for the title not being known, even if there is a ticket. Using a combination of several hundred gigabytes of word lists found online, totalling over a billion passwords/common words, no new title key passwords were found. No further attempts were made following this failure, and the data is provided as-is even without the title key to decrypt it.

## Wii

The following title ID lists were used during the initial scanning of the CDN for Wii titles:

- https://wiibrew.org/wiki/Title_database
- https://github.com/allancoding/Wii-Shop-Channel/tree/0cc733d8ed4852aa0a393c1e880890775aea04d3/server/public/oss/serv (taken from the `titleId=` part of the file names)
- https://github.com/launchshopwii/Shop-Backend/blob/707956b4caf3c30d25e04611c9dc71cfdbf60fb3/titlekey.py

No range or mutation scans were done for the Wii.

5 "disk" titles seem to exist on the CDN. Those being:

- Photo Channel 1.1 (https://wiibrew.org/wiki/Photo_Channel_1.1_dummy)
- The Legend of Zelda: Skyward Sword (JPN)
- The Legend of Zelda: Skyward Sword (USA)
- The Legend of Zelda: Skyward Sword (EUR)
- The Legend of Zelda: Skyward Sword (KOR)

The title `0001000146435954` is not on the CDN.

## DSi

The following title ID lists were used during the initial scanning of the CDN for DSi titles:

- https://dsibrew.org/wiki/Title_database
- https://3dbrew.org/wiki/3DS_DSiWare_Titles
- https://yls8.mtheall.com
- https://github.com/zedseven/NusRipper/blob/6ebe1e80ed49bc832e602619cc2682b18ca92b45/NusRipper/ReferenceFiles/DSi23DS.csv
- https://github.com/zedseven/NusRipper/blob/6ebe1e80ed49bc832e602619cc2682b18ca92b45/NusRipper/ReferenceFiles/GalaxyDatFiles.csv
- https://github.com/zedseven/NusRipper/blob/6ebe1e80ed49bc832e602619cc2682b18ca92b45/NusRipper/ReferenceFiles/GalaxyFileDates.csv
- https://github.com/zedseven/NusRipper/blob/6ebe1e80ed49bc832e602619cc2682b18ca92b45/NusRipper/ReferenceFiles/LarsenDatFiles.csv
- https://github.com/zedseven/NusRipper/blob/6ebe1e80ed49bc832e602619cc2682b18ca92b45/NusRipper/ReferenceFiles/TitlesCleaned.csv
- https://github.com/RobLoach/awesome-dats/blob/000d7cbc4def0452d693daab9e4ebcaccf6e8e01/No-Intro/Nintendo%20-%20Nintendo%20DSi%20(Digital)%20(20220506-190731).dat
- https://raw.githubusercontent.com/RobLoach/awesome-dats/000d7cbc4def0452d693daab9e4ebcaccf6e8e01/No-Intro/Nintendo%20-%20Nintendo%20DSi%20(Digital)%20(CDN)%20(Decrypted)%20(20230417-043358).dat
- https://raw.githubusercontent.com/RobLoach/awesome-dats/000d7cbc4def0452d693daab9e4ebcaccf6e8e01/No-Intro/Nintendo%20-%20Nintendo%20DSi%20(Digital)%20(CDN)%20(Encrypted)%20(20230417-043358).dat
- https://github.com/videogame-archive/dat-catalog/blob/843a568f31ccd7847a3cea1f710d351119a52960/root/normalized/No-Intro/No-Intro/Nintendo%20-%20Nintendo%20DSi%20(Digital)/Nintendo%20-%20Nintendo%20DSi%20(Digital)%20(20220506-190731).dat
- https://pastebin.com/2i8zXJn7
- https://pastebin.com/h4P9CjKg

No range or mutation scans were done for the DSi.

## 3DS

The following title ID lists were used during the initial scanning of the CDN for 3DS titles:

- https://tagaya-ctr.cdn.nintendo.net (`USA/US` region. 3DS version list only provides the latest, no past versions available)
- https://www.3dbrew.org/wiki/Title_list
- https://www.3dbrew.org/wiki/Title_list/eShop_Titles
- https://www.3dbrew.org/wiki/EShop_Demos
- https://www.3dbrew.org/wiki/Title_list/Patches
- https://www.3dbrew.org/wiki/Title_list/DLC
- https://3dbrew.org/wiki/3DS_DSiWare_Titles
- https://yls8.mtheall.com
- https://3dsdb.com
- https://raw.githubusercontent.com/PretendoNetwork/archival-tools/715426c37e2df01c2ab20d3e51f57b92b1a76b1e/idbe/title-versions.json

Following the initial scan a range scan was performed. https://www.3dbrew.org/wiki/Titles documents various parts of the title ID structure used by the 3DS, including a range of "title types" which place a title into one of 5 categories based on its title "Unique ID". These ranges were used with a "variation" of `00`.

Following the range scan a mutation scan was performed. These mutations include:

- Changing the title ID high value to that of other title types (DLC, demo, update, etc.)
- For demo/DLC titles the "variation" documented on https://www.3dbrew.org/wiki/Titles was changed to be all possible values from 00-FF

Following the mutation scan a 2nd range scan was performed, however it could not be completed. This scan covered the following title ID ranges:

- `00040000-XXXXXX00` (Base title)
- `0004000E-XXXXXX00` (Update title)
- `0004008C-XXXXXX00` (DLC title)
- `00040002-XXXXXX01` (Demo title)

Where `XXXXXX` is `000000` through `FFFFFF`. This scan was done in tandem with the Wii U, for a total of 134,217,728 title IDs. The final byte of DLC/demo titles is an "index" number, with DLCs starting at index 0 and demos at index 1. If any DLC/demo titles were found at the starting index, then all indexes up to `FF` were also checked (this may have resulted in some indexes being missed if their starting index was not on the CDN). This scan could ***not*** be fully completed. Almost exactly halfway through the 134,217,728 title IDs Nintendo closed the CDN. This scan revealed 293 3DS titles not found by other scans.

The title `0004008C01890800` is present on the CDN, and archive, but lists content file `00000041` in it's TMD. `00000041` is not on the CDN. The bad content file is left in the archive as a reference.

These scans revealed several previously undocumented/unreleased titles/versions. This includes several developer tools and demo/test applications. The archive has not been thoroughly scanned to document these cases, however some examples include:

- `00040000-0FF00000` - "Nex Test". Developer tool used to test game servers?
- `00040000-0FF10000` - "Application #1". Sample application used to test sound and graphics
- `00040000-0FF20000` - "Application #1". Sample application used to test sound and graphics
- `00040000-0FF30000` - "Save Simple BSF". Sample application used to test save games

## Wii U

The following title ID lists were used during the initial scanning of the CDN for Wii U titles:

- https://tagaya-wup.cdn.nintendo.net (`USA/US` region. Scanned all available version lists)
- https://yls8.mtheall.com
- https://wiiubrew.org/wiki/Title_database
- https://raw.githubusercontent.com/PretendoNetwork/archival-tools/715426c37e2df01c2ab20d3e51f57b92b1a76b1e/idbe/title-versions.json

Following the initial scan a range scan using the 3DS ranges (https://www.3dbrew.org/wiki/Titles) was performed.

Following the range scan a mutation scan was performed. These mutations changed only the title ID high value to that of other title types (DLC, demo, update, etc.).

Following the mutation scan a 2nd range scan was performed, however it could not be completed. This scan covered the following title ID ranges:

- `00050000-XXXXXX00` (Base title)
- `0005000E-XXXXXX00` (Update title)
- `0005000C-XXXXXX00` (DLC title)
- `00050002-XXXXXX00` (Demo title)

Where `XXXXXX` is `000000` through `FFFFFF`. This scan was done in tandem with the 3DS, for a total of 134,217,728 title IDs. This scan could ***not*** be fully completed. Almost exactly halfway through the 134,217,728 title IDs Nintendo closed the CDN. This scan revealed 156 Wii U titles not found by other scans.

These scans revealed several previously undocumented/unreleased titles/versions. The archive has not been thoroughly scanned to document these cases, however some examples include:

- `00050000-11E7B000` - "L_1E7B0_0000_ja". Seems to be a GX2 demo app? `meta.xml` says it was compiled `2012-04-02`. There are many similar titles to this as well.
- `0005000E-1F600A00` - Paper Mario Color Splash update title (USA title ID used, but applies to JPN. EUR does not exist). This game never received an official update title, and this title is not present on the retail CDN.
- `00050030-1001610A` - Miiverse (USA title ID used, but applies to all regions). https://wiiubrew.org/wiki/Title_database only documents v9, v18, v52, v83, v90, v103, v107, v112, v113, however 44 other versions exist not available on the retail CDN:
  - v1
  - v2
  - v3
  - v4
  - v5
  - v6
  - v8
  - v16
  - v17
  - v32
  - v33
  - v34
  - v35
  - v36
  - v37
  - v38
  - v39
  - v48
  - v49
  - v50
  - v51
  - v64
  - v65
  - v67
  - v68
  - v69
  - v71
  - v72
  - v73
  - v74
  - v76
  - v80
  - v81
  - v82
  - v96
  - v97
  - v98
  - v99
  - v100
  - v101
  - v102
  - v104
  - v105
  - v106

## vWii

The following title ID lists were used during the initial scanning of the CDN for vWii titles:

- https://wiiubrew.org/wiki/Title_database
- https://wiibrew.org/wiki/Title_database
- https://github.com/allancoding/Wii-Shop-Channel/tree/0cc733d8ed4852aa0a393c1e880890775aea04d3/server/public/oss/serv (taken from the `titleId=` part of the file names)
- https://github.com/launchshopwii/Shop-Backend/blob/707956b4caf3c30d25e04611c9dc71cfdbf60fb3/titlekey.py

No range or mutation scans were done for the vWii.
