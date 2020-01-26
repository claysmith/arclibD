module fonttest; 

import 	
	arc.font,
	arc.input,
	arc.window,
	arc.math.point,
	arc.math.size, 
	arc.draw.shape,
	arc.draw.color;

int main() {
  
	arc.window.open("BFont", 800, 600, 0); 
    arc.font.open();
    
	Font fontA = new Font("testbin/font.ttf", 16);
	Font fontB = new Font("testbin/font.ttf", 32);
	Font fontC = new Font("testbin/font.ttf", 16);

	Font font = new Font("testbin/font.ttf", 16); 
	
	arc.input.open(); 

	char [] text = "hello\nMy\nworld\nHOW\nare\nyOU";
    char[] text2 = "hello my world how are you";

	float width = font.getWidth(cast(char[])"world");
	float height = font.getLineSkip*6; 

	while (!arc.input.keyPressed(ARC_QUIT))
	{
		arc.input.process(); 

		arc.window.clear();

		font.draw(text, arc.input.mousePos, Color.White);
        font.draw(text2, arc.input.mousePos + Point(0,height+30), Color.White);
        
		drawRectangle(arc.input.mousePos, Size(width, height), Color.Red, false); 
        
		arc.window.swap();
	}

    scope(exit)
    {
	    arc.window.close(); 
    }
        
	return 0;
}
