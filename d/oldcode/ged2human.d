import std.stdio, std.string, std.conv;
import std.container.slist : SList;
import std.container.rbtree : RedBlackTree;
import std.array : Appender;

string peekBit(string s) {
	auto index = s.indexOf(' ');
	if (index < 0) return s;
	return s[0..index];
}
string popBit(ref string s) {
	auto index = s.indexOf(' ');
	if (index < 0) {
		string ans = s;
		s = null;
		return ans;
	} else {
		string ans = s[0..index];
		s = s[index+1..$];
		return ans;
	}
}

struct gedLine {
	int depth;
	string tag;
	string id;
	string xlink;
	string content;
	this(string line) {
		string d = line.popBit;
		if (d.length == 1) depth = d[0] - '0';
		else depth = to!int(d, 10);
		
		tag = line.popBit;
		if (tag[0] == '@' && tag[$-1] == '@') {
			id = tag[1..$-1];
			tag = line.popBit;
		}
		
		string link = line.peekBit;
		if (link.length > 0 && link[0] == '@' && link[$-1] == '@') {
			xlink = link[1..$-1];
			line.popBit;
		}
		
		content = line;
	}
	string toString() {
		string ans = "<"~tag;
		if (xlink) ans ~= " xlink:href=\"#"~xlink~"\"";
		if (id) ans ~= " id=\""~id~"\"";
		return ans ~ ">" ~ content;
	}
}

struct gedNode {
	gedLine content;
	gedNode[] children;
	@property int depth() { return content.depth; }
	this(gedLine line) { this.content = line; }
}

struct bufFile {
	File readFrom;
	string[] buffer;
	this(ref File f) { this.readFrom = f; }
	this(string fname) { this.readFrom = File(fname); }
	string peek() {
		if (buffer.length > 0) {
			return buffer[$-1];
		} else if (readFrom.eof) {
			return null;
		} else {
			buffer ~= readFrom.readln();
			return buffer[$-1];
		}
	}
	string pop() {
		if (buffer.length > 0) {
			string ans = buffer[$-1];
			buffer.length = buffer.length - 1;
			return ans;
		}
		else if (readFrom.eof) return null;
		else {
			return readFrom.readln();
		}
	}
	void push(string line) {
		buffer ~= line;
	}
}

enum KNOWN_TAGS = 
[ "ABBR":`Abbreviation`
, "ADDR":`Address`
, "AFN":null
, "AUTH":`Compiler`
, "BAPL":`Baptism (LDS)`
, "BAPM":`Baptism (non-LDS)`
, "BIRT":`Birth`
, "BLES":`Blessing`
, "BURI":`Burial`
, "CALN":`Call Number`
, "CENS":`Census`
, "CHAN":null
, "CHAR":null
, "CHIL":`Child`
, "CHR":`Christening (non-LDS)`
, "CITY":`City`
, "CONF":`Confirmation (non-LDS)`
, "CORP":`Corporation`
, "CTRY":`Country`
, "DATA":null
, "DATE":`Date`
, "DEAT":`Death`
, "DEST":null
, "DIV":`Divorce`
, "EMAIL":null
, "EMIG":`Emigration`
, "ENDL":`Endowment (LDS)`
, "EVEN":`Event (other)`
, "FAM":`Family`
, "FAMC":`Child in`
, "FAMS":`Spouse in`
, "FILE":null
, "FORM":null
, "GEDC":null
, "GIVN":`Given name`
, "HEAD":null
, "HUSB":`Husband`
, "IMMI":`Immigration`
, "INDI":`Person`
, "MARR":`Marriage`
, "MEDI":`Medium`
, "NAME":`Name`
, "NICK":`Nickname`
, "NOTE":`Note`
, "NPFX":`Name prefix`
, "NSFX":`Name suffix`
, "OBJE":null
, "OCCU":`Occupation`
, "ORDN":`Ordinance`
, "PAGE":`Page`
, "PHON":null
, "PLAC":`Place`
, "PUBL":`Publication`
, "QUAY":null // `Quality (0-3)`
, "REFN":null
, "REPO":`Repository`
, "RESI":`Residence`
, "SEX":`Sex`
, "SLGS":`Sealing (child)`
, "SOUR":`Source`
, "STAE":`State`
, "SUBM":`Submitter`
, "SURN":`Surname`
, "TEMP":`Temple`
, "TEXT":`Transcript`
, "TIME":`Time`
, "TITL":`Title`
, "TRLR":null
, "TYPE":null // `(type)` handled as part of Event (other)
, "VERS":`Version`
, "WIFE":`Wife`
, "_DATE":null
, "_NAME":`Name`
, "_PRIM":null
, "_SCBK":null
, "_TYPE":null
, "_UID":null
];


void nestedDivs(ref gedNode n, gedNode*[string] targets, File o) {
	import std.xml : encode;
	import std.array : replace;
	import std.string : strip;
	
	gedLine l = n.content;

	if (n.children.length == 0 && l.content.strip == "" && l.xlink == null) return; 

	string fancy = KNOWN_TAGS[l.tag];
	if (fancy != null) {
		if (fancy == `Event (other)` && n.children.length > 0 && n.children[0].content.tag == `TYPE`) {
			fancy = `Event(`~n.children[0].content.content~`)`;
		}
		
		o.writeln(`<div class="lvl`,l.depth,`"><strong class="lvl`,l.depth,`">`,fancy,`</strong>: `);
		if (l.xlink) {
			gedNode **refd = l.xlink in targets;
			if (refd !is null && *refd !is null) {
				gedLine *k = &((**refd).content);
				if (k.tag == `INDI`) {
					string slug = "Person "~l.xlink;
					if ((**refd).children.length > 0 && (**refd).children[0].content.tag == `NAME`)
						slug = (**refd).children[0].content.content;
					int idn = l.xlink[1..$].to!int;
					idn /= 100;
					auto page = std.format.format("people%03d.html",idn);
					o.writeln(`<a href="`,page,`#`,l.xlink,`">`,slug,`</a>`);
				} else if (k.tag == `SOUR`) {
					string slug = "Source "~l.xlink;
					if ((**refd).children.length > 0 && (**refd).children[0].content.tag == `ABBR`)
						slug = (**refd).children[0].content.content;
					else if ((**refd).children.length > 1 && (**refd).children[1].content.tag == `ABBR`)
						slug = (**refd).children[1].content.content;
					o.writeln(`<a href="sources.html#`,l.xlink,`">`,slug,`</a>`);
				} else {
					nestedDivs(**refd, targets, o);
				}
			} 
		} else {
			o.writeln(`<span class="br">`, encode(l.content.strip).replace("«tab»","&nbsp; ").replace("«","<").replace("»",">"),`</span>`);
		}
		foreach(kid; n.children) nestedDivs(kid, targets, o);
		o.writeln(`</div>`);
	}
}

void main(string[] args) {
	if (args.length == 1) {
		stderr.writeln("USAGE: ", args[0], " someGedcom.ged");
		return;
	}
	string BOM = "\uFEFF";
	RedBlackTree!string tags = new RedBlackTree!string;
	foreach(arg; args[1..$]) {
		
		Appender!(gedNode[]) level0;
		SList!gedNode stack;

		gedLine last = "0 gedcom55";
		auto s = bufFile(arg);
		string line;
		
		
		// step 1: build up the data, handling CONT and CONC tags as we go
		while((line = s.pop) != null) {
			if (line[0..BOM.length] == BOM) line = line[BOM.length..$];
			last = gedLine(line.strip());
			
			if (last.tag == "CONT") {
				stack.front.content.content ~= "\n"~last.content;
			} else if (last.tag == "CONC") {
				stack.front.content.content  ~= last.content;
			} else {
				tags.insert(last.tag);
				while (!stack.empty && stack.front.depth >= last.depth) {
					auto old = stack.front;
					stack.removeFront;
					if (stack.empty) {
						level0 ~= old;
					} else {
						stack.front.children ~= old;
					}
				}
				stack.insertFront(gedNode(last));
			}
		}
		while (!stack.empty) {
			auto old = stack.front;
			stack.removeFront;
			if (stack.empty) {
				level0 ~= old;
			} else {
				stack.front.children ~= old;
			}
		}
		
		// step 2: enter targets for crosslinks
		gedNode[] master = level0.data;
		gedNode*[string] lookups;
		foreach(i,v; master) 
			if (v.content.id != null) lookups[v.content.id] = &master[i];
		
		// step 3: display as an HTML document
		string header = `﻿<html><head><title>Automatically extraced from GEDCOM file</title>
<style type="text/css">
	section { border:1px solid black; margin:1em; border-radius:1ex; padding:1ex; }
	div { padding-left:1em; }
	.br { white-space:pre-wrap; }
//	b { padding:1px; background-color:#eee; border: 1px solid #ccc;}
	strong { padding:1px; background-color:#eee; font-weight:normal; }
</style>
</head><body>`;
		File[] individuals;
		File sources = File("html-dump/sources.html", "w");
		sources.writeln(header);

		foreach(l0; level0.data) {
			if (l0.content.tag == `INDI`) {
				int idn = l0.content.id[1..$].to!int;
				idn /= 100;
				while (individuals.length <= idn) {
					individuals ~= File(std.format.format("html-dump/people%03d.html", individuals.length),"w");
					individuals[$-1].writeln(header);
				}
				File o = individuals[idn];
				if (l0.children.length > 0 && l0.children[0].content.tag == `NAME`) {
					o.writeln(`<section><a name="`,l0.content.id,`"/><h1>`,l0.children[0].content.content,` (`,l0.content.id,`)</h1>`);
				} else {
					o.writeln(`<section><a name="`,l0.content.id,`"/><h1>Person `,l0.content.id,`</h1>`);
				}
				foreach(kid; l0.children) {
					nestedDivs(kid, lookups, o);
				}
				o.writeln(`</section>`);
			} else if (l0.content.tag == `SOUR`) {
				if (l0.children.length > 0 && l0.children[0].content.tag == `ABBR`) {
					sources.writeln(`<section><a name="`,l0.content.id,`"/><h1>`,l0.children[0].content.content,` (`,l0.content.id,`)</h1>`);
				} else if (l0.children.length > 1 && l0.children[1].content.tag == `ABBR`) {
					sources.writeln(`<section><a name="`,l0.content.id,`"/><h1>`,l0.children[1].content.content,` (`,l0.content.id,`)</h1>`);
				} else {
					sources.writeln(`<section><a name="`,l0.content.id,`"/><h1>Source `,l0.content.id,`</h1>`);
				}
				foreach(kid; l0.children) {
					nestedDivs(kid, lookups, sources);
				}
				sources.writeln(`</section>`);
			}
		}
		sources.writeln("</body></html>");
		sources.close();
		foreach(o; individuals) {
			o.writeln("</body></html>");
			o.close();
		}
		

		auto index = File("html-dump/index.html","w");
		index.writeln(header);
		index.writeln("<h1>All names in database</h1>");
		index.writeln("<ul>");
		foreach(l0; level0.data) {
			if (l0.content.tag == `INDI`) {
				int idn = l0.content.id[1..$].to!int;
				idn /= 100;
				string link = std.format.format("people%03d.html#%s", idn, l0.content.id);
				string name = "(no name)";
				if (l0.children.length > 0 && l0.children[0].content.tag == `NAME`)
					name = l0.children[0].content.content;
				index.writeln(`<li><a href="`,link,`">`,name,`</a></li>`); 
			}
		}
		index.writeln("</body></html>");
		index.close();
		
		
	}
}
