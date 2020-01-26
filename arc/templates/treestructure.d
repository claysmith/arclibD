/******************************************************************************* 

	Tree structure 

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:      ArcLib team 

	Description:    
		Tree structure, may be used for GUI menu

	Examples:      
	---------------------
int main()
{   
    TreeStructure!(char[]) tree = new TreeStructure!(char[]); 
    
    
    Node!(char[]) root = new Node!(char[]);
    
    Node!(char[]) file = new Node!(char[])("File"); 
    file.addChildData("Save"); 
    file.addChildData("Save As"); 
    file.addChildData("Open"); 
    file.addChildData("Exit"); 

    Node!(char[]) edit = new Node!(char[])("Edit"); 
    edit.addChildData("Tools"); 
    Node!(char[]) sub = new Node!(char[])("Sub");
    sub.addChildData("Child"); 

    Node!(char[]) sub2 = new Node!(char[])("Sub2"); 
    sub2.addChildData("Test"); 
    sub2.addChildData("Yo"); 
    
    sub.addChildNode(sub2);
    edit.addChildNode(sub);     
    
    Node!(char[]) about = new Node!(char[])("About"); 
    
    root.addChildNode(file); 
    root.addChildNode(edit); 
    root.addChildNode(about); 
    
    tree.setRoot(root); 

    //child.addData("Test2"); 
    
    //Node!(char[]) child2 = new Node!(char[]); 
    //child2.addData("Child2"); 
    //child.addNode(child2); 
    
    //root.addNode(child); 
    
    foreach(Node!(char[]) n; tree)
    {
        Cout("Value is " ~ n.data).newline; 
    }
    
    return 0; 
}
	---------------------

*******************************************************************************/

module arc.templates.treestructure; 

/// Node, heart of the tree
class Node(T)
{
  public:
    ///
	this()
	{
		children.length=0; 
	}    

	///
	this(T d)
	{
		children.length=0; 
		data = d; 
	}

	/// set this nodes data
	void setData(T d)
	{
		data = d; 
	}

	/// get this nodes data 
	T getData() 
	{
		return data; 
	}

	/// add child node and set its data 
	void addChildData(T d)
	{
		Node!(T) n = new Node!(T); 
		n.data = d; 

		children.length = children.length + 1; 
		children[children.length-1] = n; 
	}

	/// add child node 
	void addChildNode(Node!(T) n)
	{
		assert(n !is null); 

		children.length = children.length + 1; 
		children[children.length-1] = n;
	}

	/// get child node at index
	Node!(T) getChildNodeAtIndex(int i)
	{
		return children[i]; 
	}

	/// get child data at index
	T getChildDataAtIndex(int i)
	{
		return children[i].data; 
	}    

	/// for each iteration 
	int opApply(int delegate(ref Node!(T)) dg)
	{   
		int result = 0;

		result = iterate_tree(this, dg); 

		return result;
	}

	/// iterate recursively through the tree
	int iterate_tree(ref Node!(T) root, int delegate(ref Node!(T)) dg)
	{
		int result = 0; 

		// make sure we don't have a null root 
		assert(root !is null); 
			
		// loop over all children
		foreach(Node!(T) n; root.children)
		{
			result = dg(n); 
			if (result)
			{
				 break; 
			}
			
			// go recursively deeper if the given child has children
			if (n.children.length > 0)
			{
				iterate_tree(n, dg); 
			}
		}

		return result; 
	}
    
  public: 
	// nodes children
	Node!(T)[] children;

	// nodes data 
	T data;
	bool hasData=false;
}

/// Tree structure 
class TreeStructure(T)
{
  public: 
	///
	this()
	{
		root = new Node!(T); 
	}

	/// set the root of a tree
	void setRoot(Node!(T) rt)
	{
		root = rt; 
	}

	/// get the root value of a tree
	Node!(T) getRoot()
	{
		return root; 
	}

	/// iterate throughout the tree 
	int opApply(int delegate(ref Node!(T)) dg)
	{   
		int result = 0;

		result = root.iterate_tree(root, dg); 

		return result;
	}

  private: 
	Node!(T) root; 
}

/*
int main()
{   
    TreeStructure!(char[]) tree = new TreeStructure!(char[]); 
    
    
    Node!(char[]) root = new Node!(char[]);
    
    Node!(char[]) file = new Node!(char[])("File"); 
    file.addChildData("Save"); 
    file.addChildData("Save As"); 
    file.addChildData("Open"); 
    file.addChildData("Exit"); 

    Node!(char[]) edit = new Node!(char[])("Edit"); 
    edit.addChildData("Tools"); 
    Node!(char[]) sub = new Node!(char[])("Sub");
    sub.addChildData("Child"); 

    Node!(char[]) sub2 = new Node!(char[])("Sub2"); 
    sub2.addChildData("Test"); 
    sub2.addChildData("Yo"); 
    
    sub.addChildNode(sub2);
    edit.addChildNode(sub);     
    
    Node!(char[]) about = new Node!(char[])("About"); 
    
    root.addChildNode(file); 
    root.addChildNode(edit); 
    root.addChildNode(about); 
    
    tree.setRoot(root); 

    //child.addData("Test2"); 
    
    //Node!(char[]) child2 = new Node!(char[]); 
    //child2.addData("Child2"); 
    //child.addNode(child2); 
    
    //root.addNode(child); 
    
    foreach(Node!(char[]) n; tree)
    {
        Cout("Value is " ~ n.data).newline; 
    }
    
    return 0; 
}
*/