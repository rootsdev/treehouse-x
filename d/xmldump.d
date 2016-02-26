struct Named { string name; }
struct ExtraAttr { string key; string val; }
struct Attr {} 
struct Prop {}
struct Always {} /// only works for @Attr
struct FlatContent {} /// only works for @Prop, uses to!string with no <name resource=""/>
struct Wrapped {} /// uses <name>value</name> instead of <name resource="value"/>


template allNonstaticFields(T) {
	import std.traits;
	import std.meta;

	static if (is(T P == super)) {
        alias allNonstaticFields = AliasSeq!(staticMap!(FieldNameTuple, Reverse!(TransitiveBaseTypeTuple!T)), FieldNameTuple!T);
	} else {
		alias allNonstaticFields = FieldNameTuple!T;
	}
}

mixin template addToXML() {
	string toXML(string indent=null, string myname=null) {
		import std.traits : hasUDA, getUDAs, isArray, isSomeString;
		import std.array : Appender;
		import std.conv : to;
		import std.xml : encode;
		Appender!string sb;
		sb.put(indent);
		sb.put('<');
		if (myname.length > 0) {
			sb.put(myname);
		} else {
			static if (hasUDA!(typeof(this), Named)) {
				sb.put(getUDAs!(typeof(this), Named)[0].name);
			} else {
				sb.put(typeof(this).stringof);
			}
		}
		foreach(ea; getUDAs!(typeof(this), ExtraAttr)) {
			sb.put(' ');
			sb.put(ea.key);
			sb.put(`="`);
			sb.put(encode(ea.val));
			sb.put('"');
		}
		foreach(name; allNonstaticFields!(typeof(this))) {
			static if (hasUDA!(__traits(getMember, this, name), Attr)) {
				static if (__traits(hasMember, __traits(getMember, this, name), `toAttrString`)) {
					string value = __traits(getMember, this, name).toAttrString;
				} else {
					string value = to!string(__traits(getMember, this, name));
				}
				if (hasUDA!(__traits(getMember, this, name), Always) || value != null) {
					sb.put(' ');
					static if (hasUDA!(__traits(getMember, this, name), Named)) {
						sb.put(getUDAs!(__traits(getMember, this, name), Named)[0].name);
					} else {
						sb.put(name);
					}
					sb.put(`="`);
					sb.put(encode(value));
					sb.put('"');
				}
			}
		}
		bool got = false;
		bool newline = false;
		string newindent = indent ~ `  `;
		
		
		void putOneProp(S)(S val, string name, bool flat, bool always, bool wrapped) {
			static if (__traits(compiles, S.init == null))
				if (val == null) return;
			if (flat) {
				static if (__traits(hasMember, val, `toAttrString`)) {
					string content = val.toAttrString;
				} else {
					string content = to!string(val);
				}
				if (content.length > 0 || always) {
					sb.put(encode(content));
				}
			} else if (wrapped) {
				string content = to!string(val);
				if (content.length > 0 || always) {
					newline = true;
					sb.put('\n');
					sb.put(newindent);
					sb.put('<');
					sb.put(name);
					sb.put(`>`);
					sb.put(encode(content));
					sb.put(`</`);
					sb.put(name);
					sb.put(`>`);
				}
			} else {
				static if (__traits(hasMember, val, `toXML`)) {
					string content = val.toXML(newindent, name);
					if (content.length > 0 || always) {
						newline = true;
						sb.put('\n');
						sb.put(content);
					}
				} else {
					string content = to!string(val);
					if (content.length > 0 || always) {
						newline = true;
						sb.put('\n');
						sb.put(newindent);
						sb.put('<');
						sb.put(name);
						sb.put(` resource="`);
						sb.put(encode(content));
						sb.put(`"/>`);
					}
				}
			}
		}
		foreach(name; allNonstaticFields!(typeof(this))) {
			static if (hasUDA!(__traits(getMember, this, name), Prop)) {
				if (!got) { got = true; sb.put('>'); }
				static if (isArray!(typeof(__traits(getMember, this, name))) && !isSomeString!(typeof(__traits(getMember, this, name)))) {
					foreach(val; __traits(getMember, this, name)) {
						static if (hasUDA!(__traits(getMember, this, name), Named)) {
							putOneProp(
								val, 
								getUDAs!(__traits(getMember, this, name), Named)[0].name,
								hasUDA!(__traits(getMember, this, name), FlatContent),
								hasUDA!(__traits(getMember, this, name), Always),
								hasUDA!(__traits(getMember, this, name), Wrapped),
							);
						} else {
							putOneProp(
								val, 
								name,
								hasUDA!(__traits(getMember, this, name), FlatContent),
								hasUDA!(__traits(getMember, this, name), Always),
								hasUDA!(__traits(getMember, this, name), Wrapped),
							);
						}
					}
				} else {
					static if (hasUDA!(__traits(getMember, this, name), Named)) {
						putOneProp(
							__traits(getMember, this, name), 
							getUDAs!(__traits(getMember, this, name), Named)[0].name,
							hasUDA!(__traits(getMember, this, name), FlatContent),
							hasUDA!(__traits(getMember, this, name), Always),
							hasUDA!(__traits(getMember, this, name), Wrapped),
						);
					} else {
						putOneProp(
							__traits(getMember, this, name), 
							name,
							hasUDA!(__traits(getMember, this, name), FlatContent),
							hasUDA!(__traits(getMember, this, name), Always),
							hasUDA!(__traits(getMember, this, name), Wrapped),
						);
					}
				}
			}
		}
		if (got) {
			if (newline) { sb.put('\n'); sb.put(indent); }
			sb.put(`</`);
			if (myname.length > 0) {
				sb.put(myname);
			} else {
				static if (hasUDA!(typeof(this), Named)) {
					sb.put(getUDAs!(typeof(this), Named)[0].name);
				} else {
					sb.put(typeof(this).stringof);
				}
			}
			sb.put('>');
		} else {
			sb.put(`/>`);
		}
		
		return sb.data;
	}
}

mixin template idGenerator(string prefix) {
	private static lastId = 0;
	alias Ptr = string;
	Ptr ptr() {
		import std.conv : to;
		if (!id) id = prefix ~ to!string(++lastId);
		return `#` ~ id;
	}
}


struct Maybe(T) {
	bool exists = false;
	T value;
	void opAssign(T val) { exists = true; value = val; }
	void opAssign(typeof(null) nil) { exists = false; }
	alias value this;

	string toString() {
		import std.conv : to;
		if (!exists) return ``;
		return to!string(value);
	}
	static if (__traits(hasMember, T, `toXML`)) {
		string toXML(string indent=null, string name=null) {
			if (!exists) return ``;
			return value.toXML(indent);
		}
	}
}


version(none) {

class C {
	@Always @Prop Maybe!int hide;
}

@Named("alpha")
class B : C {
	@Prop Maybe!bool legacy;
	@Attr string id;
	
	mixin idGenerator!("beta");
	mixin addToXML;
}
class A : B {
	enum will = "call";
	@Attr string x;
	@Attr int y;
	@Named("quest") @Prop string z;
	@Prop int[] w;
	@Prop B nested;
	@Attr @Named("redun") string foo() { return x; } // will not be seen, not a field
	
	override mixin addToXML;
}

void main() {
	import std.stdio;
	
	A b = new A();
	b.x = "yes";
	b.y = 1;
	b.z = "why";
	b.w = [3,1,4,1,5];
	b.nested = new B();
	b.legacy = false;
	b.nested.ptr;
	
	writeln(b.toXML);
}

}
