/**
 * Copyright 2011 Google Inc. All Rights Reserved.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS-IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// To compile:
// 1. Use cygwin, intsall gcc and freetype2
// 2. Open a cygwin prompt and run: 
//   gcc -I/usr/include/freetype2 font2glyphs.c -o font2glyphs -lfreetype

#include <stdio.h>
#include <ft2build.h>
#include FT_FREETYPE_H

FT_Library library;
FT_Face face;

FILE *fpCurrent;

int xMax;
int yMax;
int xMin;
int yMin;

static int ft_move_to( const FT_Vector* to, void* user )
{
	fprintf(fpCurrent, "\t\t\t[1, %d, %d],\n", to->x - xMin, yMax - to->y);
	return 0;
}
static int ft_line_to( const FT_Vector* to, void* user )
{
	fprintf(fpCurrent, "\t\t\t[2, %d, %d],\n", to->x - xMin, yMax - to->y);
	return 0;
}
static int ft_conic_to( const FT_Vector* control, const FT_Vector* to, void* user )
{
	fprintf(fpCurrent, "\t\t\t[3, %d, %d, %d, %d],\n", to->x - xMin, yMax - to->y, control->x - xMin, yMax - control->y);
	return 0;
}
static int ft_cubic_to( const FT_Vector* control1, const FT_Vector* control2, const FT_Vector* to, void* user )
{
	fprintf(fpCurrent, "\t\t\t[4, %d, %d, %d, %d, %d, %d],\n", to->x - xMin, yMax - to->y, control1->x - xMin, yMax - control1->y, control2->x - xMin, yMax - control2->y);
	return 0;
}

static int ft_move_to_calc( const FT_Vector* to, void* user )
{
    if (to->x < xMin) xMin = to->x;
    if (to->x > xMax) xMax = to->x;
    
    if (to->y < yMin) yMin = to->y;
    if (to->y > yMax) yMax = to->y;
	return 0;
}
static int ft_line_to_calc( const FT_Vector* to, void* user )
{
    if (to->x < xMin) xMin = to->x;
    if (to->x > xMax) xMax = to->x;
    
    if (to->y < yMin) yMin = to->y;
    if (to->y > yMax) yMax = to->y;
	return 0;
}
static int ft_conic_to_calc( const FT_Vector* control, const FT_Vector* to, void* user )
{
    if (to->x < xMin) xMin = to->x;
    if (to->x > xMax) xMax = to->x;
    
    if (to->y < yMin) yMin = to->y;
    if (to->y > yMax) yMax = to->y;

    if (control->x < xMin) xMin = control->x;
    if (control->x > xMax) xMax = control->x;
    
    if (control->y < yMin) yMin = control->y;
    if (control->y > yMax) yMax = control->y;
	return 0;
}
static int ft_cubic_to_calc( const FT_Vector* control1, const FT_Vector* control2, const FT_Vector* to, void* user )
{
    if (to->x < xMin) xMin = to->x;
    if (to->x > xMax) xMax = to->x;
    
    if (to->y < yMin) yMin = to->y;
    if (to->y > yMax) yMax = to->y;

    if (control1->x < xMin) xMin = control1->x;
    if (control1->x > xMax) xMax = control1->x;
    
    if (control1->y < yMin) yMin = control1->y;
    if (control1->y > yMax) yMax = control1->y;

    if (control2->x < xMin) xMin = control2->x;
    if (control2->x > xMax) xMax = control2->x;
    
    if (control2->y < yMin) yMin = control2->y;
    if (control2->y > yMax) yMax = control2->y;
	return 0;
}

FT_Outline_Funcs outline_funcs = {
	ft_move_to,
	ft_line_to,
	ft_conic_to,
	ft_cubic_to,
	0, 0
};

FT_Outline_Funcs calc_funcs = {
	ft_move_to_calc,
	ft_line_to_calc,
	ft_conic_to_calc,
	ft_cubic_to_calc,
	0, 0
};

char *CleanName(char *pchIn) {
    char *pchOut = strdup(pchIn);
    int i = 0;
    char *pch = pchOut;
    while (*pch != 0) {
        char ch = *pch;
        if (ch >= 'A' && ch <= 'Z') {
            // ok
        } else if (ch >= 'a' && ch <= 'z') {
            // ok
        } else if (ch >= '0' && ch <= '9') {
            // ok
        } else {
            *pch = '_';
        }
        pch++;
    }
    return pchOut;
}

char *FileName(char *pchBase, char ch) {
    char *pchOut = malloc(sizeof(char) * (strlen(pchBase) + 30));
    strcpy(pchOut, pchBase);
    strcat(pchOut, "_");
    
    char pchNum[10];
    int nCh = ((unsigned char)(ch));
    sprintf(pchNum, "%03d", nCh);
    strcat(pchOut, pchNum);
    strcat(pchOut, ".as");
    return pchOut;
}

void PrintHead(FILE *fp) {
    fprintf(fp, "package {\n");
    fprintf(fp, "\timport flash.display.Graphics;\n");
    fprintf(fp, "\timport flash.display.Sprite;\n");
    fprintf(fp, "\t// BEGIN: Generated\n");
}

void PrintBody(FILE *fp) {
    fprintf(fp, "\t// END: Generated\n");
    fprintf(fp, "\t{\n");
    fprintf(fp, "\t\tprivate static const knMoveTo:uint = 1;\n");
    fprintf(fp, "\t\tprivate static const knLineTo:uint = 2;\n");
    fprintf(fp, "\t\tprivate static const knConicTo:uint = 3;\n");
    fprintf(fp, "\t\tprivate static const knCubicTo:uint = 4;\n");
    fprintf(fp, "\t\t// BEGIN: Generated\n");
}

void PrintTail(FILE *fp, char *pchClassName) {
    fprintf(fp, "\t\t// END: Generated\n");
    fprintf(fp, "\t\t\n");
    fprintf(fp, "\t\tpublic function %s()\n", pchClassName);
    fprintf(fp, "\t\t{\n");
    fprintf(fp, "\t\t\t// Adjust coordinates\n");
    fprintf(fp, "\t\t\tvar an:Array;\n");
    fprintf(fp, "\t\t\tvar i:Number;\n");
    fprintf(fp, "\t\t\t\n");
    fprintf(fp, "\t\t\tvar nScaleFact:Number = 100 / knMaxSize;\n");
    fprintf(fp, "\t\t\tfor each (an in kaanGlyph) {\n");
    fprintf(fp, "\t\t\t\tfor (i = 1; i < an.length; i++) {\n");
    fprintf(fp, "\t\t\t\t\tan[i] *= nScaleFact;\n");
    fprintf(fp, "\t\t\t\t}\n");
    fprintf(fp, "\t\t\t}\n");
    fprintf(fp, "\t\t\t\n");
    fprintf(fp, "\t\t\tvar gr:Graphics = this.graphics;\n");
    fprintf(fp, "\t\t\tgr.clear();\n");
    fprintf(fp, "\t\t\tgr.beginFill(0);\n");
    fprintf(fp, "\t\t\tfor each (an in kaanGlyph) {\n");
    fprintf(fp, "\t\t\t\tswitch (an[0]) {\n");
    fprintf(fp, "\t\t\t\t\tcase knMoveTo:\n");
    fprintf(fp, "\t\t\t\t\t\tgr.moveTo(an[1], an[2]);\n");
    fprintf(fp, "\t\t\t\t\t\tbreak;\n");
    fprintf(fp, "\t\t\t\t\tcase knLineTo:\n");
    fprintf(fp, "\t\t\t\t\t\tgr.lineTo(an[1], an[2]);\n");
    fprintf(fp, "\t\t\t\t\t\tbreak;\n");
    fprintf(fp, "\t\t\t\t\tcase knConicTo:\n");
    fprintf(fp, "\t\t\t\t\t\tgr.curveTo(an[3], an[4], an[1], an[2]);\n");
    fprintf(fp, "\t\t\t\t}\n");
    fprintf(fp, "\t\t\t}\n");
    fprintf(fp, "\t\t\tgr.endFill();\n");
    fprintf(fp, "\t\t}\n");
    fprintf(fp, "\t}\n");
    fprintf(fp, "}\n");
}

void CreateAS3(char *pchBaseName, char ch) {
    char *pchFileName = FileName(pchBaseName, ch);
    FILE *fp = fopen(pchFileName, "w");
    fpCurrent = fp;
    char *pchClassName = strdup(pchFileName);
    pchClassName[strlen(pchClassName)-3] = 0; // Remove hte extension
    
    // First, reset our analysis
    xMax = INT_MIN;
    xMin = INT_MAX;
    yMax = INT_MIN;
    yMin = INT_MAX;
    
    // Next, calculate these values
    FT_Outline_Decompose( &(face->glyph->outline), &calc_funcs, 0 );
    
    int xDiff = xMax - xMin;
    int yDiff = yMax - yMin;
    
    printf("Creating: %s, range(%6d to %6d, %6d to %6d)\n", pchClassName, xMin, xMax, yMin, yMax);
    
    PrintHead(fp);
  
    // Print the SWF line, like this: [SWF(width="100", height="100", backgroundColor="#FFFFFF")]
    // Print this line: "\tpublic class GlyphRender extends Sprite\n");
    
    int nNormalWidth;
    int nNormalHeight;
    if (xDiff > yDiff) {
        nNormalWidth = 100;
        nNormalHeight = 100 * yDiff / xDiff;
    } else {
        nNormalHeight = 100;
        nNormalWidth = 100 * xDiff / yDiff;
    }
    
    fprintf(fp, "\t[SWF(width=\"%d\", height=\"%d\", backgroundColor=\"#FFFFFF\")]\n", nNormalWidth, nNormalHeight);
    fprintf(fp, "\tpublic class %s extends Sprite\n", pchClassName);
    
    // Note that we should be smaprt about width/height. One the max should be 100 and the other should be proportional.
    PrintBody(fp);
    
	fprintf(fp, "\t\tprivate static const knMaxSize:Number = %d;\n", (xDiff > yDiff) ? xDiff : yDiff);
    
    // Print the array
    fprintf(fp, "\t\tprivate static const kaanGlyph:Array = [\n");
    FT_Outline_Decompose( &(face->glyph->outline), &outline_funcs, 0 );
    fprintf(fp, "\t\t];\n");
    
    PrintTail(fp, pchClassName);
    fprintf(fp, "");
}

int main(int argc, char *argv[]) {
	if (argc != 2) {
		fprintf(stderr, "usage: %s fontfile\n", argv[0]);
		return 1;
	}

	char *font_file = argv[1];

    int error = FT_Init_FreeType( &library );
    if ( error ) {
        fprintf(stderr, "an error occurred during library initialization ...\n");
    }

    error = FT_New_Face( library, font_file, 0, &face );
    if ( error == FT_Err_Unknown_File_Format ) {
        fprintf(stderr, "the font file could be opened and read, but it appears that its font format is unsupported\n");
    } else if ( error ) {
        fprintf(stderr, "another error code means that the font file could not be opened or read, or simply that it is broken\n");
    }

	error = FT_Set_Char_Size(	face, /* handle to face object */ 
								0, /* char_width in 1/64th of points */
								16*64, /* char_height in 1/64th of points */
								100000, /* horizontal device resolution */
								100000 ); /* vertical device resolution */ 
                                
	int ch;
	for (ch=0; ch<256; ch++)
	{
		FT_UInt glyph_index = FT_Get_Char_Index( face, ch );

		error = FT_Load_Glyph( face, glyph_index, FT_LOAD_DEFAULT );

		FT_BBox bbox;
		FT_Outline_Get_BBox( &(face->glyph->outline), &bbox );

        if (face->glyph->metrics.width > 0 && face->glyph->metrics.width > 0) {
            CreateAS3(CleanName(face->family_name), ch);
        }
	}

	FT_Done_Face( face );
	FT_Done_FreeType( library );
	
	return 0;
}
