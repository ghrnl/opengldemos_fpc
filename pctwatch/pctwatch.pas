//------------------------------------------------------------------------
//
// Author              : Jan Horn
// Email               : jhorn@global.co.za
// Website             : http://www.sulaco.co.za
//                       http://home.global.co.za/~jhorn
// Date                : 28 January 2002
// Version             : 1.0
// Description         : The initial project idea was to create a series of gears
//                       but that is so boring, so I added the pocket watch around it
// Virtual Pascal adaptation by Allan Mertner 2003
// fpc adaption by Gert Renkema 2021-2026
//
//------------------------------------------------------------------------
program pctwatch;

uses
  Windows,
  gl, glu,
  glProg,
  glBmp,
  WatchDat;

var
  // Textures
  WatchTex     : glUint;
  WatchFaceTex : glUint;

  // User variables
  Wireframe : Boolean;
  ShowFace  : Boolean;
  ShowCover : Boolean;
  Lighting  : Boolean;
  CaseDL, CoverDL, FaceDL : glUint;     // Case, Cover and face display Lists

  Gear1, Gear2, Gear3, Gear4 : glUint;  // Gear Display List
  Cylinder : pgluQuadric; {pgluQuadricObj;}

  // mouse
  MouseButton : Integer;              // mouse button down
  YRot, XRot: glFloat;                // current X and Y rotation
  xPos, yPos, zPos : glFloat;         // Location
  Xcoord, Ycoord, Zcoord : Integer;   // Mouse Coordinates

const
  // Ligting
  LightPosition : array[0..3] of glFloat = (-18.0, 15.0, 3.0, 0);
  MatShine   : GLfloat = 50.0;
//  amb : Array[0..3] of glFloat


{$R images.res}


{------------------------------------------------------------------}
{  Create a Displaylist for the watch and its cover                }
{------------------------------------------------------------------}
procedure createWatchDisplayList;
var I : Integer;
begin
  // Create a display list for the watch casing
  CaseDL :=glGenLists(1);
  glNewList(CaseDL, GL_COMPILE);
    glBindTexture(GL_TEXTURE_2D, WatchTex);
    glTranslatef(0, 2, -1.1);
    glScalef(3.3, 3.3, 3.3);
    glColor3f(1.0, 1.0, 1.0);

    glBegin (GL_TRIANGLES);
    for I :=0 to numCaseTriangles-1 do
    begin
      glNormal3f(CaseNormals[ CaseFace[i,3],0], CaseNormals[ CaseFace[i,3],1], CaseNormals[ CaseFace[i,3],2]);
      glVertex3f(CaseVertices[CaseFace[i,0],0], CaseVertices[CaseFace[i,0],1], CaseVertices[CaseFace[i,0],2]);

      glNormal3f(CaseNormals[ CaseFace[i,4],0], CaseNormals[ CaseFace[i,4],1], CaseNormals[ CaseFace[i,4],2]);
      glVertex3f(CaseVertices[CaseFace[i,1],0], CaseVertices[CaseFace[i,1],1], CaseVertices[CaseFace[i,1],2]);

      glNormal3f(CaseNormals[ CaseFace[i,5],0], CaseNormals[ CaseFace[i,5],1], CaseNormals[ CaseFace[i,5],2]);
      glVertex3f(CaseVertices[CaseFace[i,2],0], CaseVertices[CaseFace[i,2],1], CaseVertices[CaseFace[i,2],2]);
    end;
    glEnd ;
  glEndList;

  // Create a display list for the watch glass cover
  CoverDL :=glGenLists(1);
  glNewList(CoverDL, GL_COMPILE);
    glTranslatef(0, -0.6, 0.58);
    glScalef(0.65, 0.65, 0.65);
    glColor4f(0.8, 0.8, 0.8, 0.5);
    glEnable(GL_BLEND);
    glDisable(GL_DEPTH_TEST);

    glBegin (GL_TRIANGLES);
    for I :=0 to numCoverTriangles-1 do
    begin
      glNormal3f(CoverNormals[ CoverFace[i,3],0], CoverNormals[ CoverFace[i,3],1], CoverNormals[ CoverFace[i,3],2]);
      glVertex3f(CoverVertices[CoverFace[i,0],0], CoverVertices[CoverFace[i,0],1], CoverVertices[CoverFace[i,0],2]);

      glNormal3f(CoverNormals[ CoverFace[i,4],0], CoverNormals[ CoverFace[i,4],1], CoverNormals[ CoverFace[i,4],2]);
      glVertex3f(CoverVertices[CoverFace[i,1],0], CoverVertices[CoverFace[i,1],1], CoverVertices[CoverFace[i,1],2]);

      glNormal3f(CoverNormals[ CoverFace[i,5],0], CoverNormals[ CoverFace[i,5],1], CoverNormals[ CoverFace[i,5],2]);
      glVertex3f(CoverVertices[CoverFace[i,2],0], CoverVertices[CoverFace[i,2],1], CoverVertices[CoverFace[i,2],2]);
    end;
    glEnd ;

    glEnable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);
  glEndList;

  // Create a display list for the watch face
  FaceDL :=glGenLists(1);
  glNewList(FaceDL, GL_COMPILE);
    glBindTexture(GL_TEXTURE_2D, WatchFaceTex);
    glPushMatrix;
      glColor3f(1, 1, 1);
      glEnable(GL_TEXTURE_2D);
      glTranslatef(0, 0, 0.3);
      gluDisk(Cylinder, 0, 6.8, 64, 1);
      glRotatef(180, 1, 0, 0);
      glColor3f(0.6, 0.6, 0.7);
      glDisable(GL_TEXTURE_2D);
      glTranslatef(0, 0, -0.1);
      gluDisk(Cylinder, 0, 6.8, 64, 1);
      glColor3f(1, 1, 1);
    glPopMatrix;
  glEndList;
end;


{------------------------------------------------------------------}
{  Procedure to create a gear.                                     }
{------------------------------------------------------------------}
procedure CreateGear(InnerRadius, OuterRadius, Width: glFloat; Teeth : Integer; ToothDepth: glFloat);
var I : Integer;
    OuterRadius1, OuterRadius2 : glFloat;
    angle, da : glFloat;
    u, v, len : glFloat;
begin
  OuterRadius1 := OuterRadius - ToothDepth/2.0;
  OuterRadius2 := OuterRadius + ToothDepth/2.0;

  da := 2*Pi/teeth/4.0;
  glShadeModel(GL_FLAT);

  // front flat part of the gear
  glNormal3f(0.0, 0.0, 1.0);
  glBegin(GL_QUAD_STRIP);
    for i := 0 to teeth do
    begin
      angle := I*2*Pi/teeth;
      glVertex3f(InnerRadius *cos(angle+da/2),   InnerRadius*sin(angle+da/2),    width*0.5);
      glVertex3f(OuterRadius1*cos(angle),        OuterRadius1*sin(angle),        width*0.5);
      glVertex3f(InnerRadius *cos(angle+5*da/2), InnerRadius*sin(angle+5*da/2),  width*0.5);
      glVertex3f(OuterRadius1*cos(angle+3*da),   OuterRadius1*sin(angle+3*da),   width*0.5);
    end;
  glEnd;

  // back flat part of the gear
  glNormal3f(0.0, 0.0, -1.0);
  glBegin(GL_QUAD_STRIP);
    for I := 0 to teeth do
    begin
      angle := I*2*Pi/teeth;
      glVertex3f(OuterRadius1*cos(angle),      OuterRadius1*sin(angle),      -width*0.5);
      glVertex3f(InnerRadius *cos(angle+da/2), InnerRadius*sin(angle+da/2),  -width*0.5);
      glVertex3f(OuterRadius1*cos(angle+3*da), OuterRadius1*sin(angle+3*da), -width*0.5);
      glVertex3f(InnerRadius *cos(angle+5*da/2), InnerRadius*sin(angle+5*da/2),  -width*0.5);
    end;
  glEnd;

  // front flat part of the teeth
  glNormal3f(0.0, 0.0, 1.0);
  da := 2*Pi/teeth/4.0;
  glBegin(GL_QUADS);
    for I := 0 to Teeth - 1 do
    begin
      angle := I*2*Pi/teeth;
      glVertex3f(OuterRadius1*cos(angle),      OuterRadius1*sin(angle),      width*0.5);
      glVertex3f(OuterRadius2*cos(angle+da),   OuterRadius2*sin(angle+da),   width*0.5);
      glVertex3f(OuterRadius2*cos(angle+2*da), OuterRadius2*sin(angle+2*da), width*0.5);
      glVertex3f(OuterRadius1*cos(angle+3*da), OuterRadius1*sin(angle+3*da), width*0.5);
    end;
  glEnd;

  // back flat part of the teeth
  glNormal3f(0.0, 0.0, -1.0);
  glBegin(GL_QUADS);
    for i := 0 to teeth - 1 do
    begin
      angle := i*2.0*Pi/teeth;
      glVertex3f(OuterRadius1*cos(angle+3*da), OuterRadius1*sin(angle+3*da), -width*0.5);
      glVertex3f(OuterRadius2*cos(angle+2*da), OuterRadius2*sin(angle+2*da), -width*0.5);
      glVertex3f(OuterRadius2*cos(angle+da),   OuterRadius2*sin(angle+da),   -width*0.5);
      glVertex3f(OuterRadius1*cos(angle),      OuterRadius1*sin(angle),      -width*0.5);
    end;
  glEnd;

  // the outer circle (ie. the teeth)
  glBegin(GL_QUAD_STRIP);
    for I := 0 to Teeth - 1 do
    begin
      angle := I*2*Pi/Teeth;
      glVertex3f(OuterRadius1*cos(angle), OuterRadius1*sin(angle),  width*0.5);
      glVertex3f(OuterRadius1*cos(angle), OuterRadius1*sin(angle), -width*0.5);
      // calculate formal for tooth face
      u   := OuterRadius2*cos(angle+da) - OuterRadius1*cos(angle);
      v   := OuterRadius2*sin(angle+da) - OuterRadius1*sin(angle);
      len := sqrt(u*u + v*v);
      u   := u/len;
      v   := v/len;
      glNormal3f(v, -u, 0.0);
      glVertex3f(OuterRadius2*cos(angle+da),   OuterRadius2*sin(angle+da),    width*0.5);
      glVertex3f(OuterRadius2*cos(angle+da),   OuterRadius2*sin(angle+da),   -width*0.5);
      glNormal3f(cos(angle), sin(angle), 0.0);
      glVertex3f(OuterRadius2*cos(angle+2*da), OuterRadius2*sin(angle+2*da),  width*0.5);
      glVertex3f(OuterRadius2*cos(angle+2*da), OuterRadius2*sin(angle+2*da), -width*0.5);
      u   := OuterRadius1*cos(angle+3*da) - OuterRadius2*cos(angle+2*da);
      v   := OuterRadius1*sin(angle+3*da) - OuterRadius2*sin(angle+2*da);
      glNormal3f(v, -u, 0.0);
      glVertex3f(OuterRadius1*cos(angle+3*da), OuterRadius1*sin(angle+3*da),  width*0.5);
      glVertex3f(OuterRadius1*cos(angle+3*da), OuterRadius1*sin(angle+3*da), -width*0.5);
      glNormal3f(cos(angle), sin(angle), 0.0);
    end;
    glVertex3f(OuterRadius1*cos(0), OuterRadius1*sin(0),  width*0.5);
    glVertex3f(OuterRadius1*cos(0), OuterRadius1*sin(0), -width*0.5);
  glEnd;

  glShadeModel(GL_SMOOTH);

  // inner circle
  glBegin(GL_QUAD_STRIP);
    for I := 0 to 2*Teeth do
    begin
      angle := I*Pi/Teeth + da/2;
      glNormal3f(-cos(angle), -sin(angle), 0.0);
      glVertex3f(InnerRadius*cos(angle), InnerRadius*sin(angle), -width*0.5);
      glVertex3f(InnerRadius*cos(angle), InnerRadius*sin(angle), width*0.5);
    end;
  glEnd;
end;


{------------------------------------------------------------------}
{  Procedure to create gear spokes.  Spokes have a gap in center   }
{------------------------------------------------------------------}
procedure CreateSpokes(InnerRadius, OuterRadius : glFloat);
begin
  glBegin(GL_QUADS);
    glNormal3f( 0.0, 1.0, 0.0);
    glVertex3f( InnerRadius,  0.15, -0.15);
    glVertex3f( InnerRadius,  0.15,  0.15);
    glVertex3f( OuterRadius,  0.15,  0.15);
    glVertex3f( OuterRadius,  0.15, -0.15);

    glVertex3f(-OuterRadius,  0.15, -0.15);
    glVertex3f(-OuterRadius,  0.15,  0.15);
    glVertex3f(-InnerRadius,  0.15,  0.15);
    glVertex3f(-InnerRadius,  0.15, -0.15);

    glNormal3f( 0.0, -1.0, 0.0);
    glVertex3f( InnerRadius, -0.15, -0.15);
    glVertex3f( OuterRadius, -0.15, -0.15);
    glVertex3f( OuterRadius, -0.15,  0.15);
    glVertex3f( InnerRadius, -0.15,  0.15);

    glVertex3f(-OuterRadius, -0.15, -0.15);
    glVertex3f(-InnerRadius, -0.15, -0.15);
    glVertex3f(-InnerRadius, -0.15,  0.15);
    glVertex3f(-OuterRadius, -0.15,  0.15);

    glNormal3f( 0.0, 0.0, 1.0);
    glVertex3f( InnerRadius, -0.15,  0.15);
    glVertex3f( OuterRadius, -0.15,  0.15);
    glVertex3f( OuterRadius,  0.15,  0.15);
    glVertex3f( InnerRadius,  0.15,  0.15);

    glVertex3f(-OuterRadius, -0.15,  0.15);
    glVertex3f(-InnerRadius, -0.15,  0.15);
    glVertex3f(-InnerRadius,  0.15,  0.15);
    glVertex3f(-OuterRadius,  0.15,  0.15);

    glNormal3f( 0.0, 0.0,-1.0);
    glVertex3f( InnerRadius, -0.15, -0.15);
    glVertex3f( InnerRadius,  0.15, -0.15);
    glVertex3f( OuterRadius,  0.15, -0.15);
    glVertex3f( OuterRadius, -0.15, -0.15);

    glVertex3f(-OuterRadius, -0.15, -0.15);
    glVertex3f(-OuterRadius,  0.15, -0.15);
    glVertex3f(-InnerRadius,  0.15, -0.15);
    glVertex3f(-InnerRadius, -0.15, -0.15);
  glEnd;
end;


{------------------------------------------------------------------}
{  Procedure that creates all the gears as display lists           }
{------------------------------------------------------------------}
procedure CreateGears;
var I : Integer;
    angle : glFloat;
begin
  // big center gear
  Gear1 :=glGenLists(1);
  glNewList(Gear1, GL_COMPILE);
    CreateGear( 2.5, 3, 0.3, 32, 0.3);
    createSpokes(0.3, 2.51);
    glRotatef(90, 0, 0, 1);
    createSpokes(0.3, 2.51);
    glTranslatef(0, 0, -0.15);

    // outer and inner cylinders
    glRotatef(15, 0, 0, 1);
    gluCylinder(Cylinder, 0.4, 0.4, 0.3, 16, 1);
    glTranslatef(0, 0, 0.15);
    glBegin(GL_QUAD_STRIP);
      for I := 0 to 16 do
      begin
        angle := I*Pi/8;
        glNormal3f(-cos(angle), -sin(angle), 0.0);
        glVertex3f(0.2*cos(angle), 0.2*sin(angle), -0.3*0.5);
        glVertex3f(0.2*cos(angle), 0.2*sin(angle), 0.3*0.5);
      end;
    glEnd;

    // top and bottom covers
    glTranslatef(0, 0, 0.15);
    gluDisk(Cylinder, 0.2, 0.4, 16, 1);
    glRotatef(180, 1, 0, 0);
    glTranslatef(0, 0, 0.3);
    gluDisk(Cylinder, 0.2, 0.4, 16, 1);
  glEndList;

  // small center gear
  Gear2 :=glGenLists(1);
  glNewList(Gear2, GL_COMPILE);
    CreateGear( 0.0, 0.8, 0.3, 11, 0.3);
  glEndList;

  // gear joining center small
  Gear3 :=glGenLists(1);
  glNewList(Gear3, GL_COMPILE);
    CreateGear( 1.5, 2, 0.3, 24, 0.3);
    createSpokes(0.0, 1.51);
    glRotatef(90, 0, 0, 1);
    createSpokes(0.0, 1.51);
  glEndList;

  // smallest gear for the seconds
  Gear4 :=glGenLists(1);
  glNewList(Gear4, GL_COMPILE);
    CreateGear( 0.1, 0.6, 0.3, 7, 0.3);
  glEndList;
end;


{------------------------------------------------------------------}
{  Procedure to draw the gears                                     }
{------------------------------------------------------------------}
procedure drawGears;
begin
  glColor3f(0.7, 0.7, 0.7);
  // center big gear
  glPushMatrix;
    glRotatef(ElapsedTime/40-40, 0, 0, 1);
    glCallList(Gear1);
  glPopMatrix;

  // center small gear
  glPushMatrix;
    glRotatef(ElapsedTime/5, 0, 0, 1);
    glTranslatef(0, 0, 0.4);
    glCallList(Gear2);
    // draw joining shaft
    glTranslatef(0, 0, -0.6);
    gluCylinder(Cylinder, 0.15, 0.15, 0.8, 16, 1);
    glRotatef(180, 1, 0, 0);
    gluDisk(Cylinder, 0, 0.15, 16, 1);
  glPopMatrix;

  // gear joining center small
  glPushMatrix;
    glTranslatef(2.9, 0, 0.4);
    glRotatef(-ElapsedTime/10.91-3, 0, 0, 1);
    glCallList(Gear3);
  glPopMatrix;

  // small gear below gear above
  glPushMatrix;
    glTranslatef(2.9, 0, 0.8);
    glRotatef(-ElapsedTime/4.01+5, 0, 0, 1);
    glCallList(Gear2);
    // draw joining shaft
    glTranslatef(0, 0, -0.6);
    gluCylinder(Cylinder, 0.15, 0.15, 0.8, 16, 1);
    glRotatef(180, 1, 0, 0);
    gluDisk(Cylinder, 0, 0.15, 16, 1);
  glPopMatrix;

  // medium bottom most gear
  glPushMatrix;
    glTranslatef(3, -2.9, 0.8);
    glRotatef(ElapsedTime/8.75, 0, 0, 1);
    glCallList(Gear3);
    // draw joining shaft
    glTranslatef(0, 0, -1.0);
    gluCylinder(Cylinder, 0.15, 0.15, 1.2, 16, 1);
    glRotatef(180, 1, 0, 0);
    gluDisk(Cylinder, 0, 0.15, 16, 1);
  glPopMatrix;

  // small gear at top joining small and medium
  glPushMatrix;
    glTranslatef(3, -2.9, 0);
    glRotatef(ElapsedTime/8.75-35, 0, 0, 1);
    glCallList(Gear4);
  glPopMatrix;

  // medium gear at top joining big and seconds gear
  glPushMatrix;
    glTranslatef(1.68, -3.5, 0);
    glRotatef(-ElapsedTime/13.75+4, 0, 0, 1);
    glCallList(Gear2);
  glPopMatrix;

    // seconds gear at top for seconds
  glPushMatrix;
    glTranslatef(0.3, -4.0, 0);
    glRotatef(ElapsedTime/8.75+8, 0, 0, 1);
    glCallList(Gear4);
  glPopMatrix;
end;


{------------------------------------------------------------------}
{  Procedure to draw the watch arms                                }
{------------------------------------------------------------------}
procedure drawArms;
var SysTime : TSystemTime;
begin
  GetLocalTime(SysTime);

  glPushMatrix;
    glTranslatef(0, 0, 0.4);
      glNormal3f( 0.0, 0.0, 1.0);

    // hours
    glPushMatrix;
      glRotatef(-SysTime.wHour*30 - SysTime.wMinute/2 +90 , 0, 0, 1);
      glBegin(GL_QUADS);
        glColor3f(1, 0.2, 0.2);

        glVertex3f(-1, 0, 0);
        glVertex3f(0, -0.2, 0);
        glVertex3f(4, 0, 0);
        glVertex3f(0, 0, 0.1);

        glColor3f(0.8, 0.2, 0.2);
        glVertex3f(-1, 0, 0);
        glVertex3f(0, 0, 0.1);
        glVertex3f(4, 0, 0);
        glVertex3f(0, 0.2, 0);
      glEnd;
    glPopMatrix;

    // minutes
    glPushMatrix;
      glRotatef(-SysTime.wMinute*6 - SysTime.wSecond/10 +90, 0, 0, 1);
      glBegin(GL_QUADS);
        glColor3f(1, 0.2, 0.2);
        glVertex3f(-1, 0, 0.1);
        glVertex3f(0, -0.2, 0.1);
        glVertex3f(6, 0, 0.1);
        glVertex3f(0, 0, 0.2);

        glColor3f(0.8, 0.2, 0.2);
        glVertex3f(-1, 0, 0.1);
        glVertex3f(0, 0, 0.2);
        glVertex3f(6, 0, 0.1);
        glVertex3f(0, 0.2, 0.1);
      glEnd;
    glPopMatrix;

    // seconds
    glPushMatrix;
      glTranslatef(0, -3.94, 0);
      glRotatef(-SysTime.wSecond*6 +90, 0, 0, 1);
      glBegin(GL_QUADS);
        glVertex3f(-0.1, 0, 0);
        glVertex3f(0, -0.07, 0);
        glVertex3f(1.6, 0, 0);
        glVertex3f(0, 0.07, 0);
      glEnd;
      gluDisk(Cylinder, 0, 0.15, 8, 1);
    glPopMatrix;

  glPopMatrix;
end;


{------------------------------------------------------------------}
{  Function to draw the actual scene                               }
{------------------------------------------------------------------}
procedure glDraw;
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);    // Clear The Screen And The Depth Buffer
  glLoadIdentity;                                       // Reset The View

  glTranslatef(xPos, yPos, zPos);   // move scene to screen center
  if MouseButton=-1 then
  begin
    glRotatef(30*cos(Elapsedtime/300), 1, 0, 0);
    glRotatef(30*sin(Elapsedtime/300)+10, 0, 1, 0);
  end
  else
  begin
    glRotatef(xRot, 1, 0, 0);         // rotate to mouse coords
    glRotatef(yRot, 0, 1, 0);         // rotate to mouse coords
  end;

  // Draw the watch face and arms
  if ShowFace then
  begin
    glCallList(FaceDL);             // Draw the watch face
    drawArms;                       // draw the watch arms
  end;

  // Draw the watch cover
  if ShowCover then
  begin
    glPushMatrix;
      glEnable(GL_TEXTURE_GEN_S);   // Enable spherical
      glEnable(GL_TEXTURE_GEN_T);   // Environment Mapping
      glEnable(GL_TEXTURE_2D);
      glCallList(CaseDL);           // draw the watch cover
      glDisable(GL_TEXTURE_2D);
      if Lighting then              // if lighting then
        glCallList(CoverDL);        // draw the transparent glass cover
      glDisable(GL_TEXTURE_GEN_S);  // Disable spherical
      glDisable(GL_TEXTURE_GEN_T);  // Environment Mapping
    glPopMatrix;
  end;

  if (ShowCover = FALSE) OR Wireframe then
  begin                             // if the cover is not displayed, draw the gears
    glRotatef(180, 1, 0, 0);
    glRotatef(176, 0, 0, 1);
    drawGears;                      // draw the gears
  end;
end;


{------------------------------------------------------------------}
{  Initialise OpenGL                                               }
{------------------------------------------------------------------}
procedure glInit;
begin
  glClearColor(0.2, 0.2, 0.4, 0.0);        // Black Background
  glShadeModel(GL_SMOOTH);                 // Enables Smooth Color Shading
  glClearDepth(1.0);                       // Depth Buffer Setup
  glEnable(GL_DEPTH_TEST);                 // Enable Depth Buffer
  glDepthFunc(GL_LESS);                    // The Type Of Depth Test To Do
  glBlendFunc(GL_SRC_ALPHA, GL_ONE);

  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);   //Realy Nice perspective calculations

  glLightfv(GL_LIGHT0, GL_POSITION, @LightPosition);
  glEnable(GL_COLOR_MATERIAL);
  glEnable(GL_LIGHTING);
  glEnable(GL_CULL_FACE);  //***
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);

  glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, @MatShine);

  glEnable(GL_NORMALIZE);

  glEnable(GL_TEXTURE_2D);                      // Enable Texture Mapping
  LoadResTexture('watchfc.bmp', WatchFaceTex);
  LoadResTexture('reflect.bmp', WatchTex);

  Cylinder := gluNewQuadric;                  // Create A Pointer To The Quadric Object (Return 0 If No Memory) (NEW)
  gluQuadricNormals(Cylinder, GLU_SMOOTH);      // Create Smooth Normals
  gluQuadricTexture(Cylinder, GL_TRUE);         // Create Texture Coords

  glTexGenf(GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
  glTexGenf(GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);

  createWatchDisplayList;
  CreateGears;
  Wireframe :=FALSE;
  ShowFace  :=TRUE;
  ShowCover :=TRUE;
  Lighting  :=TRUE;
  xRot :=-5;
  xPos :=0;
  yPos :=-2.5;
  zPos :=-34;
  MouseButton :=-1;
end;

{------------------------------------------------------------------}
{  Processes all the keystrokes                                    }
{------------------------------------------------------------------}
procedure ProcessKeys;
begin
  // toggle wireframe
  if Keys[ord('W')] then
  begin
    Wireframe :=Not(Wireframe);
    if Wireframe then
      glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
    else
      glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    Keys[ord('W')] :=FALSE;
  end;

  // toggle lighting
  if Keys[ord('L')] then
  begin
    Lighting :=Not(Lighting);
    if Lighting then
      glEnable(GL_LIGHTING)
    else
      glDisable(GL_LIGHTING);
    Keys[ord('L')] :=FALSE;
  end;

  // Show/Hide watch face
  if Keys[ord('F')] then
  begin
    ShowFace :=Not(ShowFace);
    Keys[ord('F')] :=FALSE;
  end;

  // Show/Hide watch cover
  if Keys[ord('C')] then
  begin
    ShowCover :=Not(ShowCover);
    Keys[ord('C')] :=FALSE;
  end;
end;


{------------------------------------------------------------------}
{  Determines the application’s response to the messages received  }
{------------------------------------------------------------------}
function MyWndProc(hWnd: HWND; Msg: UINT;  wParam: WPARAM;  lParam: LPARAM): LRESULT; stdcall;
begin
  case (Msg) of
    // Mouse buttons
    WM_LBUTTONDOWN:
      begin
        ReleaseCapture;   // need them here, because if mouse moves off
        SetCapture(h_Wnd);  // window and returns, it needs to reset status
        MouseButton := 1;
        Xcoord := LOWORD(lParam);
        Ycoord := HIWORD(lParam);
        Result := 0;
      end;
    WM_LBUTTONUP:
      begin
        ReleaseCapture;   // above
        MouseButton := 0;
        XCoord := 0;
        YCoord := 0;
        Result := 0;
      end;
    WM_RBUTTONDOWN:
      begin
        ReleaseCapture;   // need them here, because if mouse moves off
        SetCapture(h_Wnd);  // window and returns, it needs to reset status
        MouseButton := 2;
        ZCoord :=HIWORD(lParam);
        Result := 0;
      end;
    WM_RBUTTONUP:
      begin
        ReleaseCapture;   // above
        MouseButton := 0;
        Result := 0;
      end;
    WM_MBUTTONDOWN:
      begin
        ReleaseCapture;   // need them here, because if mouse moves off
        SetCapture(h_Wnd);  // window and returns, it needs to reset status
        MouseButton := 3;
        Xcoord := LOWORD(lParam);
        Ycoord := HIWORD(lParam);
        Result := 0;
      end;
    WM_MBUTTONUP:
      begin
        ReleaseCapture;   // above
        MouseButton := 0;
        Result := 0;
      end;
    WM_MOUSEMOVE:
      begin
        if MouseButton = 1 then
        begin
          xRot := xRot + (HIWORD(lParam) - Ycoord)/2;  // moving up and down = rot around X-axis
          yRot := yRot + (LOWORD(lParam) - Xcoord)/2;
          Xcoord := LOWORD(lParam);
          Ycoord := HIWORD(lParam);
        end;
        if MouseButton = 2 then
        begin
          zPos :=zPos - (HIWORD(lParam)-ZCoord)/10;
          Zcoord := HIWORD(lParam);
        end;
        if MouseButton = 3 then
        begin
          xPos := xPos + (LOWORD(lParam)-xCoord)/24;
          yPos := yPos - (HIWORD(lParam)-yCoord)/24;
          Xcoord := LOWORD(lParam);
          Ycoord := HIWORD(lParam);
        end;
        Result := 0;
      end;
  end;
end;

begin
  RunOpenGLDemo('Pocket Watch by Jan Horn', glInit, glDraw, ProcessKeys, MyWndProc);
end.
