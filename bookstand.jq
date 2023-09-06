module {
    name: "bookstand",
    description: "Create jekyll files for ibook annotations",
    version: "1.0.0",
    author: "nntrn",
    repository: "github.com/nntrn/bookstand"
};

def epublocation($cfi):
  $cfi
  | gsub("[^0-9]";"-") | gsub("^[-]+";"") | gsub("[-]+$";"";"x") | gsub("[-]{1,}";"-")
  | split("-")|.[1:]
  | map(select(length < 5)|tonumber)
  ;

def squo: [39]|implode;

def squote($text): [squo,$text,squo]|join("");
def dquote($text): "\"\($text)\"";

def unsmart($text): $text | gsub("[“”]";"\"") | gsub("[’‘]";"'");
def unsmart: unsmart(.);

def get_tags($tag): $tag | ascii_downcase|split(" & ")|first|gsub(" "; "-");
def get_tags: get_tags(.);

def get_author($a):
  (($a|split("(\\s)?[;&,]+";"x")|.[0]|gsub("[':]";"")|gsub("[\\.\\s]+";"-")|ascii_downcase)?);

def get_author: get_author(.);

def remove_citations($text):
  $text | gsub("(?<period>[;\\.\",\\”])[0-9]{1,2}$";.period+""; "x");

def remove_citations: remove_citations(.);

def slugify($text):
  $text|tostring|ascii_downcase| split("[:&\\?\\.](\\s)?";"x")[0]
  | [[match("(?<a>[a-zA-Z0-9]+).*?";"ig")] | .[].string] | join("-");

def split_long_title($text):
  $text
  | split("\\s?[(:)]\\s?";"x")
  | (map(select(length > 0))| [.[0],(.[1:]|map(select(contains("Volume"))))]|flatten|join(" "));

def slugify2($text):
  ([39]|implode) as $squo
  | (if ($text|length)>40 then split_long_title($text) else $text end)
  | ascii_downcase
  | gsub($squo;"";"x")
  | gsub("[\\*\"]";"";"x")
  | gsub("[^a-zA-Z0-9]+";"-";"x")
  | gsub("-$";"";"x")
  ;


def wrap_text($text):
  $text
  | gsub("[\\s]{2,}";" ";"x")
  | unsmart
  | split("\n")
  | (.[0]|tostring|gsub("^[\\s]+";"")) as $first | .[1:] as $last
  | [ "*  \($first)", ($last|map("   \(.)")) ]
  | flatten(2)
  | join("\n")
  | gsub("(?<a>[^\\s])[0-9]{1,2}"; .a; "x");

def markdown_tmpl:
  [
    "---",
    "title: \(if (.title|test(":")) then dquote(.title) else (.title) end)",
    "author: \(.author)",
    "assetid: \(.assetid)",
    "date: \(.created)",
    "modified: \(.modified)",
    "tags: \(.tags|@json)",
    "slug: \(.slug)",
    "---",
    "",
    .text,
    ""
  ]| join ("\n");

def heading($text;$index):
  if ($text|length)>0 then "\n## \($text)\n" elif ($index|tonumber) > 0 then "\n---\n" else "" end;

def group_by_chapter:
  sort_by(.booklocation)
  | group_by(.ZPLLOCATIONRANGESTART)
  | to_entries
  | map( .key as $k | .value |
    [ heading(.[0].ZFUTUREPROOFING5; $k),
      (map(wrap_text(.ZANNOTATIONSELECTEDTEXT|remove_citations))|join("\n\n"))
    ]  | join("\n"))
  | flatten
  | join("\n");

def annotation_base:
  map( select((.ZTITLE) and (.ZANNOTATIONSELECTEDTEXT|length) >10) |
    . + {booklocation: epublocation(.ZANNOTATIONLOCATION) })
  | group_by(.ZASSETID)
  | map({
      assetid: .[0].ZASSETID,
      title: .[0].ZTITLE,
      # title: ((if (.[0].ZTITLE|test(":")) then dquote(.[0].ZTITLE) else (.[0].ZTITLE) end)),
      author: .[0].ZAUTHOR,
      created: min_by(.ZANNOTATIONCREATIONDATE).ZANNOTATIONCREATIONDATE,
      modified: max_by(.ZANNOTATIONCREATIONDATE).ZANNOTATIONCREATIONDATE,
      tags: (.[0].ZGENRE|get_tags),
      slug: slugify2(.[0].ZTITLE),
      count: length,
      text: group_by_chapter
    });

def annotation_base2:
  map( select((.ZTITLE) and (.ZANNOTATIONSELECTEDTEXT|length) >10) |
    . + {booklocation: epublocation(.ZANNOTATIONLOCATION) })
  | group_by(.ZASSETID)
  | map({
      assetid: .[0].ZASSETID,
      title: (if (.[0].ZTITLE|test(":")) then dquote(.[0].ZTITLE) else (.[0].ZTITLE) end),
      author: .[0].ZAUTHOR,
      created: min_by(.ZANNOTATIONCREATIONDATE).ZANNOTATIONCREATIONDATE,
      modified: max_by(.ZANNOTATIONCREATIONDATE).ZANNOTATIONCREATIONDATE,
      tags: (.[0].ZGENRE|get_tags),
      slug: slugify2(.[0].ZTITLE),
      count: length,
      annotations: (map({
        text: (.ZANNOTATIONSELECTEDTEXT),
        location: (.booklocation|.[1:]),
        date:.ZANNOTATIONCREATIONDATE
      })| sort_by(.location) | map(.location |= join("-")))
    });

def book_list:
  annotation_base
  | map(del(.text) | . + {cover: "/assets/artwork/\(.assetid).jpg"} );


def format_text:
  gsub("[\\t]{2,}";"\t";"")
  | gsub("[\\n]{2,}";"\n";"x")
  | gsub("[\\n\\s\\t]+$";"";"x")
  ;

def annotation_list:
  sort_by(.ZANNOTATIONCREATIONDATE)
  | map({
    assetid: .ZASSETID,
    text: (.ZANNOTATIONSELECTEDTEXT|remove_citations|format_text),
    created: .ZANNOTATIONCREATIONDATE,
    cfi: (epublocation(.ZANNOTATIONLOCATION)|join("-"))
  });

def annotation_tags:
  unique_by(.ZASSETID)
  | map(select(.ZTITLE))
  | annotation_base
  | group_by(.tags)
  | map({
      name: .[0].tags,
      count: length,
      books: map({title,assetid,slug})
    });

def annotation_json:
  annotation_base|map(del(.text,.created,.modified,.slug));

def create_markdown:
  annotation_base
  | map( @sh "echo \( markdown_tmpl )" + " | cat -s > \(env.OUTDIR//"ibooks")/\(
      if env.SLUGDATE then (.created|fromdate|strftime("%F"))+"-" else "" end )\(.slug).md");
