module xml; 

import 
	tango.text.xml.Document, 
	tango.text.xml.DocPrinter,
	tango.io.File,
	tango.io.Stdout;

int main() 
{
	{
		// 1) Write test XML file /////////////////////////////
		// create XML node for writing out to a file 
		auto doc = new Document!(char);

		// attach an xml header
		doc.header;

		// attach an element with some attributes, plus
		// a child element with an attached data value
		auto rootNode = doc.tree.element(null, "root"); 
		
		for (int i = 0; i < 4; i++)
		{
			char[] eye = tango.text.convert.Integer.toString(i+1); 
			
			rootNode.element(null, "child"~eye, "Message from Child")
				.attribute(null, "a1", "v"~eye)
				.attribute(null, "a2", "v"~eye)
				.attribute(null, "a3", "v"~eye);
		}

		auto print = new DocPrinter!(char);
		
		// write to file
		File file = new File("test.xml");
		file.write(print(doc)); 
	}
	
	// 2) Load XML data and print it /////////////////////////
	{
		File file = new File("test.xml"); 
		
		auto doc = new Document!(char);
		doc.parse(cast(char[])file.read());

		auto print = new DocPrinter!(char);
		Stdout(print(doc)).newline;
	}
	

	return 0;
}
