/**
 * This file is intended to parse the GEDCOM Data Representation Grammar,
 * as defined in Chapter 1 of the various versions of the GEDCOM standard.
 * It does not attempt to enforce the schema from Chapter 2 or Appendix A.
 */

private {

/// returns the top non-space token of $(D s)	
string peekBit(string s, bool skipspace=true) {
	import std.string : indexOf;
	size_t start = -1, index = -1;
	while (index == start) {
		start += 1;
		index = s.indexOf(' ',start);
	}
	if (index < 0) return s;
	if (skipspace) return s[start..index];
	else return s[0..index];
}
/// like $(D peekBit), but also advances past the token returned
string popBit(ref string s, bool skipspace=true) {
	import std.string : indexOf;

	ptrdiff_t start = -1, index = -1;
	while (index == start) {
		start += 1;
		index = s.indexOf(' ',start);
	}

	if (index < 0) {
		string ans = s;
		s = s[$..$];
		return ans;
	} else {
//import std.stdio : stderr; stderr.writeln(s,"[",start,"..",index,"]");
		string ans;
		if (skipspace) ans = s[start..index];
		else ans = s[0..index];
		s = s[index+1..$];
		return ans;
	}
}


/// a buffered wrapper on $(D std.stdio.File)
struct bufFile {
	import std.stdio : File;
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

} // end private {...}


/// a single "line" in GEDCOM (which might be >1 line in the file due to CONC an CONT.
/// These are (level )(xref_id )?(tag)( line_value)?([\n\r]|\r\n)
struct gedLine {
	int depth;
	string tag;
	string id;
	string content;
	this(string line) {
		import std.conv : to;
		string d = line.popBit;
		if (d.length == 1) depth = d[0] - '0';
		else depth = to!int(d, 10);
		
		tag = line.popBit;
		if (tag[0] == '@' && tag[$-1] == '@') {
			id = tag[1..$-1];
			tag = line.popBit;
		}
		content = line;

		// from the standard, appendix A under CONC: "GEDCOM values are trimmed of trailing spaces"
		while (content.length > 0 && content[$-1] == ' ')
			content = content[0..$-1];

		// from the standard, appendix A under CONC: "look for the first non-space starting after the tag to determine the beginning of the value. [...] When importing values from CONT lines the reader should assume only one delimiter character following the CONT tag. Assume that the rest of the leading spaces are to be a part of the value."
		if (tag != `CONT`)
			while (content.length > 0 && content[0] == ' ')
				content = content[1..$];
	}
	bool isPointer() {
		return content.length > 0 && content[0] == '@';
	}
	string[2] xlink() {
		import std.string : indexOf;
		auto index = content.indexOf('!');
		if (index < 0) return [content[1..$-1], null];
		if (index == 1) return [null, content[2..$-1]];
		return [content[1..index], content[index+1..$-1]];
	}
	string toString() {
		string ans;
		foreach(i; 0..depth) ans ~= "  ";
		ans ~= "<"~tag;
		if (isPointer) ans ~= " xlink:href=\"#"~xlink[0]~"\"";
		if (id) ans ~= " id=\""~id~"\"";
		return ans ~ ">" ~ content;
	}
}

/// A gedcom node: a line, possibly with other nodes of depth +1 nested inside
struct gedNode {
	gedLine line;
	gedNode[] children;
	gedFile *gf;
	this(gedLine line) { this.line = line; }
	this(gedLine line, gedFile *gf) { this.line = line; this.gf = gf; }
	int depth() { return line.depth; }
	string tag() { return line.tag; }
	string id() { return line.id; }
	bool isPointer() { return line.isPointer; }
	string[2] xlink() { return isPointer ? line.xlink : [``,``]; }
	ref string content() { return line.content; }
	gedNode* findId(string seek) {
		if (id == seek) return &this;
		foreach(ref n; children) {
			auto found = n.findId(seek);
			if (found != null) return found;
		}
		return null;
	}
	
	string raw() {
		import std.conv : to;
		string ans;
		ans ~= to!string([to!string(depth), id, tag, to!string(isPointer), content]);
		foreach(child; children)
			ans ~= "\n" ~ child.raw;
		return ans;
	}
	
	string toXML() {
		string ans;
		foreach(i; 0..depth) ans ~= "  ";
		ans ~= "<"~tag;
		if (id) ans ~= " id=\""~id~"\"";
		if (isPointer) {
			ans ~= " xlink:href=\"#"~xlink[0]~"\"";
			if (children.length == 0) ans ~= "/>";
			else {
				ans ~= ">";
				foreach(n; children) ans ~= "\n"~n.toXML;
				ans ~= "\n";
				foreach(i; 0..depth) ans ~= "  ";
				ans ~= "</"~tag~">";
			}
		} else {
			if (content.length > 0) ans ~= ">" ~ content;
			else if (children.length == 0) ans ~= "/>";
			else ans ~= ">";
			foreach(n; children) ans ~= "\n"~n.toXML;
			if (children.length > 0) {
				ans ~= "\n";
				foreach(i; 0..depth) ans ~= "  ";
				ans ~= "</"~tag~">";
			} else if (content.length > 0) {
				ans ~= "</"~tag~">";
			}
		}
		return ans;
	}
	
	gedNode* followPointer() {
		if (!isPointer) return &this;
		if (gf != null) return gf.followPointer(this);
		return null;
	}
}

struct gedFile {
	gedNode[] nodes;
	size_t[string] anchors;
	
	/// Returns $(D &this) if not a pointer, or the pointed-to node otherwise.
	/// If this is a pointer but the identifier goes nowhere, returns $(D null).
	/// Note: the pointers returned by this method are not robust to node additions
	gedNode* followPointer(ref gedNode owner) {
		if (!owner.isPointer) return &owner;
		auto id = owner.xlink[0];
		assert(id != null, "FIXME: intranode pointers not implemented");
		if (id !in anchors) return null;
		auto nestedId = owner.xlink[1];
		if (nestedId == null) return &nodes[anchors[id]];
		return nodes[anchors[id]].findId(nestedId);
	}
	
	string toString() {
		import std.conv : to;
		return `gedcom file with `~to!string(nodes.length)~` top-level nodes`;
	}
}

/// main entry point: given a filename, opens the file and parses the gedcom it contains.
gedFile parseFile(string arg) {
	import std.string : strip;
	import std.container.slist : SList;
	import std.array : Appender;

	gedFile retval;

	string BOM = "\uFEFF";
	
	Appender!(gedNode[]) level0;
	SList!gedNode stack;

	gedLine gl;// = "0 gedcom55";
	auto s = bufFile(arg);
	string line;
	
	// step 1: build up the data, handling CONT and CONC tags as we go
	while((line = s.pop) != null) {
		if (line[0..BOM.length] == BOM) line = line[BOM.length..$];
		gl = gedLine(line.strip());
		
		if (gl.tag == "CONT") {
			stack.front.content ~= "\n"~gl.content;
		} else if (gl.tag == "CONC") {
			stack.front.content ~= gl.content;
		} else {
			while (!stack.empty && stack.front.depth >= gl.depth) {
				auto old = stack.front;
				stack.removeFront;
				if (stack.empty) {
					level0 ~= old;
				} else {
					stack.front.children ~= old;
				}
			}
			stack.insertFront(gedNode(gl, &retval));
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
	retval.nodes = level0.data;
	
	// step 2: populate the top-level identifiers into anchors AA
	foreach(idx, node; retval.nodes) {
		if (node.id) retval.anchors[node.id] = idx;
	}
	
	return retval;
}
