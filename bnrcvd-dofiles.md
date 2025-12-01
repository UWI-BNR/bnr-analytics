# Catalogue of Stata `.do` Files  
This document provides a structured, hyperlink-enabled catalogue of all Stata `.do` files contained within the **BNR Analytics** repository.  
Each entry includes the file name, version (if applicable), and a concise description of the file’s purpose within the BNR-CVD data processing and reporting workflow.

---

| NAME | VERSION | DESCRIPTION |
| --- | --- | --- |
| UTILITIES | | |
| `bnrcvd-dofiles.md` | -- | Documentation of all `.do` files and their functional roles. |
| [`bnrcvd-redcap.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-redcap-export.do) | -- | Exports data from the REDCap Core BNR-CVD database (PID 670), capturing raw data as strings for downstream processing. Uses python (PyCap) for this API export. |
| [`bnrcvd-2023-redcap-debug.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-2023-redcap-debug.do) | -- | Provided diagnostics for the REDCap API Export routine, used during development of `bnrcvd-2023-redcap.do` |
| [`bnrcvd-globals.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-globals.do) | 0.9 | Defines global macros used across all BNR-CVD analytics scripts, including directory paths, color HEX values, UNICODE graphics markers, and more. |
| [`bnrcvd-unwpp.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-unwpp.do) | 0.9 | Uses the United Nationas WPP API to extract and prepare UN World Population Prospects data into analysis-ready population denominators for rate calculations. Uses python to complete this API export. |
| 2009–2023 WORKFLOW SCRTIPTS |  |  |
| [`bnrcvd-2023-prep1.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-2023-prep1.do) | 0.9 | Uses the full cumulative dataset (2009–2023) to create an analysis-ready but still identifiable dataset. |
| [`bnrcvd-2023-forensics1.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-2023-forensics1.do) | 1.0 | This file is not part of the main analytics. This DO file explores alternative datasets as possible candidates to contribute to the cumulative dataset. |
| [`bnrcvd-2023-forensics2.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-2023-forensics2.do) | 1.0 | This file is not part of the main analytics. This DO file highlights the poor DM/ folder and file structure in the BNR file repository as of Nov-2025 |
| [`bnrcvd-2023-count.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-2023-count.do) | -- | DO file to create the 2023 Briefing called *Hospital Cardiovascular Cases in Barbados* |
| [`bnrcvd-2023-incidence.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-2023-incidence.do) | -- | DO file to create the 2023 Briefing called *Hospital Cardiovascular Event Rate in Barbados* |
| [`bnrcvd-2023-case-fatality.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-2023-case-fatality.do) | -- | DO file to create the 2023 Briefing called *In-Hospital Cardiovascular Deaths in Barbados* |
| [`bnrcvd-2023-length-of-stay.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-2023-length-of-stay.do) | -- | DO file to create the 2023 Briefing called *Hospital Stay Among Cardiovascular Patients in Barbados* |
| [`bnrcvd-2023-missing.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-2023-missing.do) | -- | DO file that creates a single Excel spreadsheet containing a series of tables looking at levels of missing data in key BNR registry variables through time (2010 - 2023). The Excel spreadsheet is available [on the new BNR website](https://uwi-bnr.github.io/resource-hub/2Data/dataset/dataquality/) |
| [`bnrcvd-2023-missing-collect.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-2023-missing-collect.do) | -- | This is short DO file utility that is used repeatedly in the main *missing* DO file `bnrcvd-2023-missing.do`. |
| [`bnrcvd-2023-performance.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-2023-performance.do) | -- | This is an **AS YET INCOMPLETE** DO file that will look at hospital-based CVD clinical-care performance measures. |
| [`bnrcvd-2023-tabulations.do`](https://github.com/UWI-BNR/bnr-analytics/blob/main/bnrcvd-2023-tabulations.do) | -- | This DO file creates a series of MARKDOWN and EXCEL data tables that can be seen on the BNR web page: [Data Tables 2023](https://uwi-bnr.github.io/resource-hub/3Reporting/datatables/) |
