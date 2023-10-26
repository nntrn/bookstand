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
  | map(select(length < 5)|tonumber);

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
  $text
  | gsub("(?<period>[;\\.\",\\”\\”])[0-9]{1,2}$";.period+""; "x")
  | gsub("(?<notnumber>[^0-9])\\.[0-9]+(?<whitespace>[\\s\\n]+)";.notnumber+"."+.whitespace;"x");

def remove_citations: remove_citations(.);

def split_long_title($text):
  $text
  | split("\\s?[(:)]\\s?";"x")
  | (map(select(length > 0))| [.[0],(.[1:]|map(select(contains("Volume"))))]|flatten|join(" "));

def slugify($text):
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
  | join("\n");

def list_item($text):
  $text
  | split("\n")
  | (.[0]|tostring|gsub("^[\\s]+";"")) as $first | .[1:] as $last
  | [ "\n*  \($first)", ($last|map("   \(.)")) ]
  | flatten(2)
  | join("\n");

def list_item: list_item(.);

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
    "description: \(dquote("Book highlights for "+.title+" by "+.author))",
    "---",
    ""
  ] | join("\n");

def heading($text;$index):
  if ($text|length)>0 then "\n## \($text)\n" elif ($index|tonumber) > 0 then "\n---\n" else "" end;

def format_text:
  split("[\\n\\t]+";"x")
  | map(select(test("[a-zA-Z]")) | gsub("^[\\t\\s]+";"";"x"))
  | join("\n")
  | gsub("[\\s\\t]+$";"";"x")
  | gsub("\\s\\n(?<x>[a-xA-Z])"; " "+ .x)
  | gsub("[\\n]{2,}";"\n\n";"x")
  | gsub("(?<f>[a-z])\\n(?<s>[a-z])";.f + " " + .s;"x")
  ;

def group_by_chapter:
  sort_by(.booklocation)
  | group_by(.ZPLLOCATIONRANGESTART)
  | to_entries
  | map( .key as $k | .value |
    [ heading(.[0].ZFUTUREPROOFING5; $k),
      (map(.ZANNOTATIONSELECTEDTEXT|remove_citations|unsmart|format_text|list_item)|join("\n\n"))
    ]  | join("\n"))
  | flatten
  | join("\n");

def annotation_base:
  map( select((.ZTITLE) and (.ZANNOTATIONSELECTEDTEXT|length) >10) |
    . + { booklocation: epublocation(.ZANNOTATIONLOCATION), ZTITLE: (.ZTITLE|gsub("\"";"") | gsub("\\([^0-9]+\\)"; "";"x"))})
  | group_by(.ZASSETID)
  | map({
      assetid: .[0].ZASSETID,
      title: .[0].ZTITLE,
      author: .[0].ZAUTHOR,
      created: min_by(.ZANNOTATIONCREATIONDATE).ZANNOTATIONCREATIONDATE,
      modified: max_by(.ZANNOTATIONCREATIONDATE).ZANNOTATIONCREATIONDATE,
      tags: (.[0].ZGENRE|get_tags),
      slug: slugify(.[0].ZTITLE),
      count: length,
      text: group_by_chapter
    });

def book_list:
  annotation_base | map(del(.text));

def chaptername($location):
  $location
  | capture("\\[(?<chapter>[^\\]]+)\\]").chapter
  | gsub("[0-9]{6,}|margins|\\.?xhtml|epub|ebook|\\.html";"";"xi")
  | gsub("[_-]+";" ")
  | gsub("[\\s ]$";"";"x")
  | gsub("(?<w>[a-zA-Z])(?<d>[0-9])"; .w + " " + .d)
  | gsub("^[xc][hapter ]+";"Chapter ";"xi")
  | gsub(" [0]+(?<n>[1-9])";" " +.n)
  ;

def activity_list:
  map(select((.ZTITLE) and (.ZANNOTATIONSELECTEDTEXT|length) >10))
  | sort_by(.ZANNOTATIONCREATIONDATE)
  | map({
    id: .Z_PK,
    assetid: .ZASSETID,
    text: (.ZANNOTATIONSELECTEDTEXT|remove_citations|format_text),
    created: .ZANNOTATIONCREATIONDATE,
    cfi: (epublocation(.ZANNOTATIONLOCATION)),
    chapter: (if ((.ZFUTUREPROOFING5|length)>0) then .ZFUTUREPROOFING5 else chaptername(.ZANNOTATIONLOCATION) end),
    rangestart: .ZPLLOCATIONRANGESTART
  })
  | sort_by(.cfi)
  | map(.cfi |= join("-"));

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

def create_post_markdown:
  annotation_base | map(
    @sh "echo \( markdown_tmpl )" +
    " | cat -s > docs/_posts/\(.created|fromdate|strftime("%F"))-\(.slug).md"
  );

def create_annotations_markdown($out):
  annotation_base
  | map( @sh "echo \( markdown_tmpl )" + " | cat -s > \($out)/\(.slug).md" )
  | join("\n\n");

def create_annotations_markdown: . | create_annotations_markdown("docs/_annotations");

def create_tag_markdown($out):
  map({
    title: .name,
    content: ([
      "---",
      "title: \"Tag: \(.name)\"",
      "tags: \(.name)",
      "layout: tag",
      "---"
    ] | join("\n"))
  })
  | map(@sh "echo -e \(.content) >"+ "\($out)/\(.title).html")
  | join("\n\n");

def create_tag_markdown: . | create_tag_markdown("docs/_tags");

def scale_coverart($scale;$url):
 $url|gsub(
  "(?<w>[0-9]+)x(?<h>[0-9]+)bb.jpg";
  ([((.w|tonumber)/$scale|ceil),"x",((.h|tonumber)/$scale|ceil),"bb.jpg"]|join(""));"x");
