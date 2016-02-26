import gedcomparser;
import gxconceptual;
import std.datetime : SysTime;
import std.stdio : stderr;

/// GEDCOM 5.5 uses a set of language strings, not IETF language tags
enum gedcomLanguages = [
	"Afrikaans":"",
	"Albanian":"",
	"Anglo-Saxon":"",
	"Catalan":"",
	"Catalan_Spn":"",
	"Czech":"",
	"Danish":"",
	"Dutch":"",
	"English":"en",
	"Esperanto":"",
	"Estonian":"",
	"Faroese":"",
	"Finnish":"",
	"French":"",
	"German":"",
	"Hawaiian":"",
	"Hungarian":"",
	"Icelandic":"",
	"Indonesian":"",
	"Italian":"",
	"Latvian":"",
	"Lithuanian":"",
	"Navaho":"",
	"Norwegian":"",
	"Polish":"",
	"Portuguese":"",
	"Romanian":"",
	"Serbo_Croa":"",
	"Slovak":"",
	"Slovene":"",
	"Spanish":"",
	"Swedish":"",
	"Turkish":"",
	"Wendic":"",
	"Amharic":"",
	"Arabic":"",
	"Armenian":"",
	"Assamese":"",
	"Belorusian":"",
	"Bengali":"",
	"Braj":"",
	"Bulgarian":"",
	"Burmese":"",
	"Cantonese":"",
	"Church-Slavic":"",
	"Dogri":"",
	"Georgian":"",
	"Greek":"",
	"Gujarati":"",
	"Hebrew":"",
	"Hindi":"",
	"Japanese":"",
	"Kannada":"",
	"Khmer":"",
	"Konkani":"",
	"Korean":"",
	"Lahnda":"",
	"Lao":"",
	"Macedonian":"",
	"Maithili":"",
	"Malayalam":"",
	"Mandrin":"",
	"Manipuri":"",
	"Marathi":"",
	"Mewari":"",
	"Nepali":"",
	"Oriya":"",
	"Pahari":"",
	"Pali":"",
	"Panjabi":"",
	"Persian":"",
	"Prakrit":"",
	"Pusto":"",
	"Rajasthani":"",
	"Russian":"",
	"Sanskrit":"",
	"Serb":"",
	"Tagalog":"",
	"Tamil":"",
	"Telugu":"",
	"Thai":"",
	"Tibetan":"",
	"Ukrainian":"",
	"Urdu":"",
	"Vietnamese":"",
	"Yiddish":"",
];

string exportTool;

SysTime parseDateNode(ref gedNode node) {
	import std.regex;
	import std.datetime;
	import std.uni : toUpper;
	enum base = ctRegex!(`([0-9]{1,2}\b)?\s*(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)?\s*(\b[0-9]+)(/[0-9][0-9])?\s*(B.C.)?`,`i`);
	auto cap = matchFirst(node.content, base);
	DateTime dt;
	if (cap) {
		import std.conv : to;
		Date date;
		if (cap[5].length > 0) date.yearBC = to!int(cap[3]);
		else date.year = to!int(cap[3]);
		if (cap[2].length > 0) date.month = [
			`JAN`:Month.jan,
			`FEB`:Month.feb,
			`MAR`:Month.mar,
			`APR`:Month.apr,
			`MAY`:Month.may,
			`JUN`:Month.jun,
			`JUL`:Month.jul,
			`AUG`:Month.aug,
			`SEP`:Month.sep,
			`OCT`:Month.oct,
			`NOV`:Month.nov,
			`DEC`:Month.dec,
		][cap[2].toUpper];
		if (cap[1].length > 0) date.day = to!int(cap[1]);
		dt.date = date;
	}
	if (node.children.length > 0) {
		auto node2 = node.children[0];
		assert(node2.tag == `TIME`, `DATE node with child `~node2.tag~`, not TIME?`);
		stderr.writeln(`FIXME: parse DATE TIME like`, node2);
	}
	return SysTime(dt);
}

Address parseADDR(ref gedNode node) {
	auto ans = new Address();
	if (node.children.length == 0) {
		ans.value = node.content;
	} else {
		stderr.writeln("FIXME: add parsing of structured gedcom addresses");
	}
	return ans;
}


Agent parseSUBM(ref gedNode node) {
	Agent submitter = new Agent();
	if (node.id) submitter.id = node.id;
	foreach(ref n; node.children) {
		switch(n.tag) {
			case `NAME`:
				TextValue tv; tv.value = n.content;
				submitter.names ~= tv;
				break;
			case `PHON`:
				submitter.phones ~= (`tel:`~n.content);
				break;
			case `ADDR`:
				submitter.addresses ~= parseADDR(n);
				break;
			case `LANG`:
				stderr.writeln("WARNING: submitter language preferences (like ",n.content,") are not part of the gedcomx specification");
				break;
			case `RFN`: /* no useful data */ break;
			case `RIN`:
				// a second identifier; "A unique record identification number assigned to the record by the source system. This number is intended to serve as a more sure means of identification of a record between two interfacing systems."
				// gedcom-x has identifiers for agents, but they are pointers to Subjects (Person, Relationship, Event, Place)
				break;
			case `DATE`:
				stderr.writeln(`gedcom-x does not store modifcation dates of people`);
				break;
			case `EMAIL`:
				submitter.emails ~= (`mailto:`~n.content);
				break;
			default:
				stderr.writeln("FIXME: add SUBM "~n.tag~" parsing\n",n);
		}
	}
	return submitter;
}

void parseHead(Gedcomx self, ref gedNode node) {
	self.attribution = new Attribution();

	string[] about;
	foreach(ref n; node.children) {
		switch(n.tag) {
			case `SOUR`:
				about ~= ["GEDCOM file exported from "~n.content];
				exportTool = n.content;
				break;
			case `DEST`:
				// no meaningful data here
				break;
			case `DATE`:
				self.attribution.modified = parseDateNode(n);
				break;
			case `SUBM`:
				auto agent = parseSUBM(*n.followPointer);
				self.agents ~= agent;
				self.attribution.contributor = agent.ptr;
				break;
			case `SUBN`:
				// no meaningful data here
				break;
			case `FILE`:
				// no meaningful data here
				break;
			case `COPR`:
				// copyright not part of the gedcomx standard
				stderr.writeln("WARNING: copyright notices (like ",n.content,") are not part of the gedcomx specification");
				break;
			case `GEDC`:
				if(n.children[0].content[0..3] != `5.5`) {
					stderr.writeln("WARNING: incompatible GEDCOM version ",n.children[0].content);
				}
				if(n.children[1].content != `LINEAGE-LINKED`) {
					stderr.writeln("WARNING: incompatible GEDCOM type ",n.children[1].content);
				}
				break;
			case `CHAR`:
				if(n.content != `UTF-8` && n.content != `ASCII`) {
					stderr.writeln("WARNING: incompatible charset ",n.content);
				}
				break;
			case `LANG`:
				self.lang = gedcomLanguages[n.content];
				break;
			case `PLAC`:
				about ~= ["GEDCOM file is about "~n.children[0].content];
				break;
			case `NOTE`:
				about ~= [(*node.followPointer).content];
				break;
			default:
				stderr.writeln("FIXME: add custom HEAD "~n.tag~" parsing");
		}
	}
	if (about) { // TODO: determine the "right" way to add notes to a file
		auto description = new SourceDescription();
		foreach(comment ; about) {
			auto note = new Note();
			note.text = comment;
			description.notes ~= note;
		}
		self.sourceDescriptions ~= description;
		self.description = description.ptr;
	}
}

void parseTopLevel(Gedcomx self, ref gedNode node) {
	switch(node.tag) {
		case `SUBM`: // already handled in parseHead
			break;
		case `TRLR`: // has no semantics
			break;
		case `INDI`:
			pragma(msg, `FIXME: add INDI parsing`);
			break;
		case `FAM`:
			pragma(msg, `FIXME: add FAM parsing`);
			break;
		case `NOTE`: // handled in the referring location
			break;
		case `SOUR`:
			pragma(msg, `FIXME: add SOUR parsing`);
			break;
		case `REPO`:
			pragma(msg, `FIXME: add REPO parsing`);
			break;
		default:
			stderr.writeln(`FIXME: unhandled tag `, node.tag, ` (`,__FILE__,`:`,__LINE__,`)`);
	}
}

Gedcomx gxFromGedcom(string filename) {
	auto gf = parseFile(filename);
	
	Gedcomx result = new Gedcomx();
	result.parseHead(gf.nodes[0]);
	
	foreach(node; gf.nodes[1..$]) {
		result.parseTopLevel(node);
	}
	
	return result;
}

int main(string[] args) {
	import std.stdio;
	static import std.file;
	if(args.length != 2 || !std.file.exists(args[1])) {
		writeln(`USEAGE: `, args[0],` gedcomfile.ged`);
		return 1;
	} 
	
	Gedcomx result = gxFromGedcom(args[1]);

	writeln(`<?xml version="1.0" encoding="UTF-8" standalone="yes"?>`);
	writeln(result.toXML);

	return 0;
}

