//------------------------------------------------------------------------
//
// Author              : Jan Horn
// Email               : jhorn@global.co.za
// Website             : http://home.global.co.za/~jhorn
// Date                : 8 July 2001
// Version             : 1.0
// Description         : Uses the stencil buffer to clip drawing area of images
// Virtual Pascal adaptation by Allan Mertner 2003
// fpc adaption by Gert Renkema 2021-2026
//
//------------------------------------------------------------------------
program Stencil;

uses
  Windows,
  gl, glu,
  glProg,
  glBmp;

const
  SCALING_FACTOR1 = 16;
  SCALING_FACTOR2 = 64;

var
  // Textures
  // MyTextureTex : glUint;

  // User vaiables
  KnotDL : glUint;
  Xcoord, Ycoord : Integer;

procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external 'opengl32.dll';

{------------------------------------------------------------------}
{  Function to create and draw a knot                              }
{------------------------------------------------------------------}
procedure createKnot(RADIUS1, RADIUS2, RADIUS3 : glFloat);
type glCoord = Record
       X, Y, Z : glFloat;
     end;
     glColors = Record
       R, G, B : glFloat;
     end;
     TmyObject = Record
       numfaces, numverts, numsides : Integer;
       faces    : Array [0..SCALING_FACTOR1 * SCALING_FACTOR2 * 4 * 4 - 1] of gluint;    //numfaces*numsides
       vertices : Array [0..SCALING_FACTOR1 * SCALING_FACTOR2 - 1] of glCoord;           //numverts
       Colors   : Array [0..SCALING_FACTOR1 * SCALING_FACTOR2 - 1] of GLColors;          //numverts
     end;
var Knot : TmyObject;
    I, J, Count1, Count2 : Integer;
    Alpha, Beta, Distance, MinDistance, Rotation : glFloat;
    X, Y, Z, dx, dy, dz : glFLoat;
    Value, modulus, dist : glFloat;
    index1, index2 : Integer;
begin
  Knot.numSides :=4;

  Alpha :=0;
  for Count2 :=0 to SCALING_FACTOR2-1 do
  begin
    Alpha :=Alpha + 2*PI / SCALING_FACTOR2;
    X := RADIUS2 * cos(2 * Alpha) + RADIUS1 * sin(Alpha);
    Y := RADIUS2 * sin(2 * Alpha) + RADIUS1 * cos(Alpha);
    Z := RADIUS2 * cos(3 * Alpha);
    dx := -2 * RADIUS2 * sin(2 * Alpha) + RADIUS1 * cos(Alpha);
    dy := 2 * RADIUS2 * cos(2 * Alpha) - RADIUS1 * sin(Alpha);
    dz := -3 * RADIUS2 * sin(3 * Alpha);
    Value := sqrt(dx * dx + dz * dz);
    Modulus := sqrt(dx * dx + dy * dy + dz * dz);

    Beta :=0;
    For Count1 :=0 to SCALING_FACTOR1-1 do
    begin
      Beta :=Beta + 2 * PI / SCALING_FACTOR1;

      Knot.vertices[Knot.numverts].x := X - RADIUS3 * (cos(Beta) * dz - sin(Beta) * dx * dy / Modulus) / Value;
      Knot.vertices[Knot.numverts].y := Y - RADIUS3 * sin(Beta) * Value / Modulus;
      Knot.vertices[Knot.numverts].z := Z + RADIUS3 * (cos(Beta) * dx + sin(Beta) * dy * dz / Modulus) / Value;


      dist := sqrt(Knot.vertices[Knot.numverts].x*Knot.vertices[Knot.numverts].x +
                   Knot.vertices[Knot.numverts].y*Knot.vertices[Knot.numverts].y +
                   Knot.vertices[Knot.numverts].z*Knot.vertices[Knot.numverts].z);

      Knot.colors[Knot.numverts].r := ((2/dist)+(0.5*sin(Beta)+0.4))/2.0;
      Knot.colors[Knot.numverts].g := ((2/dist)+(0.5*sin(Beta)+0.4))/2.0;
      Knot.colors[Knot.numverts].b := ((2/dist)+(0.5*sin(Beta)+0.4))/2.0;

      Inc(Knot.numverts);
    end;
  end;

  for Count1 := 0 to SCALING_FACTOR2-1 do
  begin
    Index1 := Count1 * SCALING_FACTOR1;
    Index2 := Index1 + SCALING_FACTOR1;
    Index2 := Index2 MOD Knot.numverts;
    Rotation := 0;
    MinDistance := (Knot.vertices[Index1].x - Knot.vertices[Index2].x) * (Knot.vertices[Index1].x - Knot.vertices[Index2].x) +
                   (Knot.vertices[Index1].y - Knot.vertices[Index2].y) * (Knot.vertices[Index1].y - Knot.vertices[Index2].y) +
                   (Knot.vertices[Index1].z - Knot.vertices[Index2].z) * (Knot.vertices[Index1].z - Knot.vertices[Index2].z);
    for Count2 := 1 to SCALING_FACTOR1-1 do
    begin
      Index2 := Count2 + Index1 + SCALING_FACTOR1;
      if Count1 = SCALING_FACTOR2 - 1 then
        Index2 := Count2;
      Distance := (Knot.vertices[Index1].x - Knot.vertices[Index2].x) * (Knot.vertices[Index1].x - Knot.vertices[Index2].x) +
                  (Knot.vertices[Index1].y - Knot.vertices[Index2].y) * (Knot.vertices[Index1].y - Knot.vertices[Index2].y) +
                  (Knot.vertices[Index1].z - Knot.vertices[Index2].z) * (Knot.vertices[Index1].z - Knot.vertices[Index2].z);
      if Distance < MinDistance then
      begin
        MinDistance := Distance;
        Rotation := Count2;
      end;
    end;

    for Count2 := 0 to SCALING_FACTOR1 -1 do
    begin
      Knot.faces[4*(Index1+Count2)+0] := Index1 + Count2;

      Index2 := Count2 + 1;
      Index2 := Index2 MOD SCALING_FACTOR1;
      Knot.faces[4*(Index1+Count2)+1] := Index1 + Index2;

      Index2 := Round(Count2 + Rotation + 1);
      Index2 := Index2 MOD SCALING_FACTOR1;
      Knot.faces[4*(Index1+Count2)+2] := (Index1 + Index2 + SCALING_FACTOR1) MOD  Knot.numverts;

      Index2 := Round(Count2 + Rotation);
      Index2 := Index2 MOD SCALING_FACTOR1;

      Knot.faces[4*(Index1+Count2)+3] := (Index1 + Index2 + SCALING_FACTOR1) MOD Knot.numverts;
      Inc(Knot.numfaces);
    end;
  end;

  KnotDL :=glGenLists(1);
  glNewList(KnotDL, GL_COMPILE);
    glBegin(GL_QUADS);
      J := Knot.numfaces*4;
      for I :=0 to J do
      begin
        Count1 := Knot.faces[i];
        glColor3f(Knot.Colors[Count1].r*2, Knot.Colors[Count1].g, Knot.Colors[Count1].b);
        glVertex3f(Knot.vertices[Count1].x, Knot.vertices[Count1].y,  Knot.vertices[Count1].z);
      end;
    glEnd;
  glEndList;
end;


{------------------------------------------------------------------}
{  Function to draw the actual scene                               }
{------------------------------------------------------------------}
procedure glDraw;
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);    // Clear The Screen And The Depth Buffer and Stencil Buffers
  glLoadIdentity;                         // Reset The View
  glTranslatef(0.0,0.0,-20);

  // Create a square area in the stencil buffer
  glPolygonMode(GL_FRONT, GL_FILL);
  glPolygonMode(GL_BACK, GL_FILL);
  glStencilFunc(GL_ALWAYS, 1, 1);
  glStencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE);
  glBegin(GL_QUADS);
    glVertex3f(-1.0 + Xcoord/100, -1.0 - Ycoord/100,  13.0);
    glVertex3f( 1.0 + Xcoord/100, -1.0 - Ycoord/100,  13.0);
    glVertex3f( 1.0 + Xcoord/100,  1.0 - Ycoord/100,  13.0);
    glVertex3f(-1.0 + Xcoord/100,  1.0 - Ycoord/100,  13.0);
  glEnd;


  // clear buffers and draw screen and draw only in that square area
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);    // Clear The Screen And The Depth Buffer
  glStencilFunc(GL_EQUAL, 1, 1);
  glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);

  // set wireframe mode
  glPolygonMode(GL_FRONT, GL_LINE);
  glPolygonMode(GL_BACK, GL_LINE);

  // draw a square border sothat you can see where the square is
  glLineWidth(2);         // set a thick line for square border
  glColor3f(1, 1, 1);     // draw a white boder
  glBegin(GL_QUADS);      // draw the square borders
    glVertex3f(-1.0 + Xcoord/100, -1.0 - Ycoord/100,  13.0);
    glVertex3f( 1.0 + Xcoord/100, -1.0 - Ycoord/100,  13.0);
    glVertex3f( 1.0 + Xcoord/100,  1.0 - Ycoord/100,  13.0);
    glVertex3f(-1.0 + Xcoord/100,  1.0 - Ycoord/100,  13.0);
  glEnd;
  glLineWidth(1);         // restore line thickness

  //Rotate and draw the wireframe knot
  glRotatef(ElapsedTime/10, 1, 0, 0);
  glRotatef(ElapsedTime/8, 0, 1, 0);

  glCallList(KnotDL);

  // now draw in the area that is not in the square (Not equal to sqaure area)
  glStencilFunc(GL_NOTEQUAL, 1, 1);
  glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);

  glPolygonMode(GL_FRONT, GL_FILL);
  glPolygonMode(GL_BACK, GL_FILL);
  glCallList(KnotDL);
end;


{------------------------------------------------------------------}
{  Initialise OpenGL                                               }
{------------------------------------------------------------------}
procedure glInit;
begin
  glClearColor(0.0, 0.0, 0.0, 0.0);        // Black Background
  glShadeModel(GL_SMOOTH);                 // Enables Smooth Color Shading
  glClearDepth(1.0);                       // Depth Buffer Setup
  glEnable(GL_DEPTH_TEST);                 // Enable Depth Testing
  glDepthFunc(GL_LESS);                    // The Type Of Depth Test To Do
  glEnable(GL_STENCIL_TEST);    {** ENABLE STENCIL BUFFER **}

  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);   //Realy Nice perspective calculations

  createKnot(2, 4.0, 1.0);
//    createKnot(5, 0.0, 1.5); torus
end;


{------------------------------------------------------------------}
{  Handle window resize                                            }
{------------------------------------------------------------------}
procedure glResizeWnd(Width, Height : Integer);
begin
  if (Height = 0) then                // prevent divide by zero exception
    Height := 1;
  glViewport(0, 0, Width, Height);    // Set the viewport for the OpenGL window
  glMatrixMode(GL_PROJECTION);        // Change Matrix Mode to Projection
  glLoadIdentity;                   // Reset View
  gluPerspective(45.0, Width/Height, 1.0, 100.0);  // Do the perspective calculations. Last value = max clipping depth

  glMatrixMode(GL_MODELVIEW);         // Return to the modelview matrix
  glLoadIdentity;                   // Reset View
end;

{------------------------------------------------------------------}
{  Determines the application’s response to the messages received  }
{------------------------------------------------------------------}
function MyWndProc(hWnd: HWND; Msg: UINT;  wParam: WPARAM;  lParam: LPARAM): LRESULT; stdcall;
// var
//   Buff: array[0..MAX_PATH] of Char;
begin
  case (Msg) of
    WM_MOUSEMOVE:
      begin
        Xcoord := LOWORD(lParam) - 400;   //  width/2
        Ycoord := HIWORD(lParam) - 300;   //  height/2
        Result := 0;
      end;
  end;
end;

begin
  UseStencil := True;
  HideCursor := True;
  RunOpenGLDemo('Stencil Buffer App by Jan Horn', glInit, glDraw, nil, MyWndProc);
end.
