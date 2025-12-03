{smcl}
{* *! version 1.0  02nov2025}{...}
{title:Title}

{phang}
{bf:bnryaml} {hline 2} Generate a small YAML metadata file (.yml) to accompany a BNR dataset (.dta)

{title:Syntax}

{p 8 15 2}
{cmd:bnryaml} {it:using} {cmd:,}
{opth title(string)}
{opth version(string)}
{opth created(string)}
{opth tier(string)}
{opth temporal(string)}
{opth spatial(string)}
{opth description(string)}
{opth registry(string)}
{opth content(string)}
{opth creator(string)}
{opth language(string)}
{opth format(string)}
{opth rights(string)}
{opth source(string)}
{opth contact(string)}
[{opth outfile(string)}]

{pstd}
where {it:using} is the path to the dataset
(e.g. {it:"BNR-CVD-INDIV-DEID-202312-v1.0.dta"}). The command writes a sibling
YAML file (same stem, {.yml} extension) unless {cmd:outfile()} is supplied.

{title:Description}

{pstd}
{cmd:bnryaml} writes a compact, machine- and human-readable metadata file
({.yml}) for a BNR dataset ({.dta}). The YAML records the dataset’s identity,
coverage, privacy tier, and provenance to support reproducibility, automation,
and an auditable release history.

{title:Options}

{phang}
{opth title(string)} Plain-language title for the dataset.

{phang}
{opth version(string)} Dataset version string (e.g., {cmd:"1.0"}, {cmd:"1.1"}).
This complements the {it:YYYYMM} coverage in the filename by tracking updates
and fixes within the same coverage period.

{phang}
{opth created(string)} Creation date, typically {it:YYYY-MM-DD}.

{phang}
{opth tier(string)} Privacy tier; allowed values are {cmd:FULL}, {cmd:DEID},
{cmd:ANON}.

{phang}
{opth temporal(string)} Temporal coverage (e.g., {cmd:"2009-01 to 2023-12"}).

{phang}
{opth spatial(string)} Spatial coverage (e.g., {cmd:"Barbados"}).

{phang}
{opth description(string)} One–two sentence description of dataset contents.

{phang}
{opth registry(string)} Registry/program code (e.g., {cmd:"CVD"}).

{phang}
{opth content(string)} Dataset type; allowed values are
{cmd:INDIV} (row-per-event),
{cmd:AGGR} (aggregated/summarised),
{cmd:LINK} (minimal internal linkage file).

{phang}
{opth creator(string)} Person or team responsible for creating the dataset
(e.g., {cmd:"BNR Analytics Team, GA-CDRC"}).

{phang}
{opth language(string)} Language of the dataset/labels (e.g., {cmd:"en"}).

{phang}
{opth format(string)} File format/version (e.g., {cmd:"Stata 18"}).

{phang}
{opth rights(string)} Use/redistribution statement.

{phang}
{opth source(string)} Primary data sources used.

{phang}
{opth contact(string)} Contact email or team for queries/access.

{phang}
{opth outfile(string)} Optional explicit path for the YAML file. If omitted,
the YAML is written next to the input {.dta} with a {.yml} extension.

{title:Remarks}

{pstd}
{ul:Filename convention} (recommended):
{break}{cmd:BNR-CVD-<CONTENT>-<TIER>-<YYYYMM>-v<VERSION>.dta}
where {it:<YYYYMM>} is the final month of coverage; {it:v<VERSION>} is semantic
versioning of the release.

{pstd}
{ul:Paths and quoting:} Wrap paths in compound double quotes to handle spaces.
On Windows, forward slashes are accepted by Stata and avoid escaping headaches.

{p 12 16 2}
{cmd:local} out {cmd:`"}{it:${tempdata}/BNR-CVD-INDIV-DEID-202312-v1.0.dta}{cmd:"'}

{pstd}
{ul:Scope:} {cmd:bnryaml} writes a small, flat YAML focused on identity,
coverage, tier, and provenance. If you need additional fields later, extend the
ado by adding new options and corresponding write lines.

{title:Examples}

{pstd}
{ul:1) Write YAML next to the dataset}

{cmd}
. sysuse auto, clear
. save "BNR-CVD-INDIV-DEID-202312-v1.0.dta", replace
. local out "BNR-CVD-INDIV-DEID-202312-v1.0.dta"
. bnryaml using "`out'", ///
    title("BNR-CVD Individual Dataset (De-identified)") ///
    version("1.0") ///
    created("2025-01-15") ///
    tier("DEID") ///
    temporal("2009-01 to 2023-12") ///
    spatial("Barbados") ///
    description("Confirmed cardiovascular events; cumulative through Dec 2023.") ///
    registry("CVD") ///
    content("INDIV") ///
    creator("BNR Analytics Team, GA-CDRC") ///
    language("en") ///
    format("Stata 18") ///
    rights("Restricted – internal analytical use only") ///
    source("Hospital admissions (QEH) and national death registration") ///
    contact("bnr@cavehill.uwi.edu")
{txt}

{pstd}
{ul:2) Write YAML to an explicit location}

{cmd}
. local out    "BNR-CVD-AGGR-ANON-202606-v1.0.dta"
. local ymlto  "metadata/BNR-CVD-AGGR-ANON-202606-v1.0.yml"
. bnryaml using "`out'", outfile("`ymlto'") ///
    title("BNR-CVD Aggregated Dataset (Anon)") ///
    version("1.0") created("2026-07-10") tier("ANON") ///
    temporal("2009-01 to 2026-06") spatial("Barbados") ///
    description("Aggregated counts/rates for public release.") ///
    registry("CVD") content("AGGR") creator("BNR Analytics Team") ///
    language("en") format("Stata 18") rights("Open with attribution") ///
    source("Hospital admissions and national death registration") ///
    contact("bnr@cavehill.uwi.edu")
{txt}

{pstd}
{ul:3) Programmatic check of output path}

{cmd}
. return list
{txt}
{it:r(yml)}  — local macro with the full path to the written YAML file

{title:Saved results}

{pstd}
{cmd:bnryaml} saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(yml)}}full path to the created YAML file{p_end}

{title:Diagnostics and errors}

{phang}
{err:invalid file specification} — Check for embedded or doubled quotes in the
constructed output path, or illegal characters in {cmd:outfile()}.

{phang}
{err:file not found} — If implemented in your local copy, indicates the {.dta}
path in {it:using} does not exist.

{phang}
{err:option value not allowed} — Ensure {cmd:tier()} is one of {cmd:FULL},
{cmd:DEID}, {cmd:ANON} and {cmd:content()} is one of {cmd:INDIV}, {cmd:AGGR},
{cmd:LINK}.

{title:Author}

{pstd}
BNR Consult / CaribData — Analytics & Engineering.

{title:Acknowledgments}

{pstd}
Developed for the BNR refit to support reproducible releases and automated
reporting pipelines.

{title:Also see}

{psee}
{bf:Filename convention:} {it:BNR-CVD-<CONTENT>-<TIER>-<YYYYMM>-v<VERSION>.dta}{break}
{bf:BNR docs:} Dataset Metadata Standards (internal){break}
{help file write}, {help file open}, {help macro}, {help smcl}

