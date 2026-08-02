//----------------------------------------------------------------------------
//
// Author              : Jan Horn
// Email               : jhorn@global.co.za
// Website             : http://home.global.co.za/~jhorn
// Date                : 8 April 2001
// Description         : Load BMP files for OpenGL projects
// Usage               : LoadTexture(BMPFilename, TextureName);
//                       eg : LoadTexture('logo.bmp', LogoTex);
//
//----------------------------------------------------------------------------
// fpc adaption by Gert Renkema 2021-2026
//----------------------------------------------------------------------------

unit glBmp;

interface

uses
  Windows, Strings, gl, glu;

function LoadTexture(Filename: String; var Texture: GLuint): Boolean;
function LoadResTexture(ResFilename: String; var Texture : GLuint) : Boolean;

implementation

var
  Buff: Array[0..255] of Char;

{------------------------------------------------------------------}
{  Load BMP file                                                   }
{------------------------------------------------------------------}
procedure LoadBitmap(Filename: String; var Width: Cardinal; var Height: Cardinal; var pData: Pointer);
var
  FileHeader: TBITMAPFILEHEADER;
  InfoHeader: TBITMAPINFOHEADER;
  Palette: Pointer;
  BitmapFile: THandle;
  BitmapLength: Cardinal;
  PaletteLength: Cardinal;
  ReadBytes: DWord;
  Front: ^Byte;
  Back: ^Byte;
  Temp: Byte;
  I : Cardinal;
begin
  BitmapFile := CreateFile(StrPCopy(Buff, Filename), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
  if (BitmapFile = INVALID_HANDLE_VALUE) then begin
    MessageBox(0, StrPCopy(Buff, 'Error opening "' + Filename), 'BMP Unit', MB_OK);
    Exit;
  end;

  // Get header information
  ReadFile(BitmapFile, FileHeader, SizeOf(FileHeader), ReadBytes, nil);
  ReadFile(BitmapFile, InfoHeader, SizeOf(InfoHeader), ReadBytes, nil);

  // Get palette
  PaletteLength := InfoHeader.biClrUsed;
  GetMem(Palette, PaletteLength);
  ReadFile(BitmapFile, Palette, PaletteLength, ReadBytes, nil);
  if (ReadBytes <> PaletteLength) then begin
    MessageBox(0, 'Error reading palette', 'BMP Unit', MB_OK);
    Exit;
  end;

  Width := InfoHeader.biWidth;
  Height := InfoHeader.biHeight;
  BitmapLength := InfoHeader.biSizeImage;
  if BitmapLength = 0 then
    BitmapLength := Width * Height * InfoHeader.biBitCount Div 8;

  // Get the actual pixel data
  GetMem(pData, BitmapLength);
  ReadFile(BitmapFile, pData^, BitmapLength, ReadBytes, nil);
  if (ReadBytes <> BitmapLength) then begin
    MessageBox(0, 'Error reading bitmap data', 'BMP Unit', MB_OK);
    Exit;
  end;
  CloseHandle(BitmapFile);

  // Bitmaps are stored BGR and not RGB, so swap the R and B bytes.
  for I :=0 to Width * Height - 1 do
  begin
    Front := Pointer(Cardinal(pData) + I*3);
    Back := Pointer(Cardinal(pData) + I*3 + 2);
    Temp := Front^;
    Front^ := Back^;
    Back^ := Temp;
  end;
  Freemem(palette) {GRE to prevent a memory leak }
end;


{------------------------------------------------------------------}
{  Load BMP textures                                               }
{------------------------------------------------------------------}
function LoadTexture(Filename: String; var Texture: GLuint): Boolean;
var
  pData: Pointer;
  Width: Cardinal;
  Height: Cardinal;
begin
  pData :=nil;
  LoadBitmap(Filename, Width, Height, pData);

  if (Assigned(pData)) then
    Result := True
  else
  begin
    Result := False;
    MessageBox(0, StrPCopy(Buff, 'Unable to load ' + filename), 'Loading Textures', MB_OK);
    Halt(1);
  end;

  glGenTextures(1, @Texture);
  glBindTexture(GL_TEXTURE_2D, Texture);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);  {Texture blends with object background}
//  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);  {Texture does NOT blend with object background}

  { Select a filtering type. BiLinear filtering produces very good results with little performance impact
    GL_NEAREST               - Basic texture (grainy looking texture)
    GL_LINEAR                - BiLinear filtering
    GL_LINEAR_MIPMAP_NEAREST - Basic mipmapped texture
    GL_LINEAR_MIPMAP_LINEAR  - BiLinear Mipmapped texture
  }

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); { only first two can be used }
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); { all of the above can be used }

  gluBuild2DMipmaps(GL_TEXTURE_2D, 3, Width, Height, GL_RGB, GL_UNSIGNED_BYTE, pData);
//  glTexImage2D(GL_TEXTURE_2D, 0, 3, Width, Height, 0, GL_RGB, GL_UNSIGNED_BYTE, pData);  // Use when not wanting mipmaps to be built by openGL
  Freemem(pData) {GRE to prevent a memory leak }
end;

{------------------------------------------------------------------}
{  Create the Texture                                              }
{------------------------------------------------------------------}
function CreateTexture(Width, Height, Format : Word; pData : Pointer) : Integer;
var
  Texture : GLuint;
begin
  glGenTextures(1, @Texture);
  glBindTexture(GL_TEXTURE_2D, Texture);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);  {Texture blends with object background}
//  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);  {Texture does NOT blend with object background}

  { Select a filtering type. BiLinear filtering produces very good results with little performance impact
    GL_NEAREST               - Basic texture (grainy looking texture)
    GL_LINEAR                - BiLinear filtering
    GL_LINEAR_MIPMAP_NEAREST - Basic mipmapped texture
    GL_LINEAR_MIPMAP_LINEAR  - BiLinear Mipmapped texture
  }

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); { only first two can be used }
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); { all of the above can be used }

  if Format = GL_RGBA then
    gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGBA, Width, Height, GL_RGBA, GL_UNSIGNED_BYTE, pData)
  else
    gluBuild2DMipmaps(GL_TEXTURE_2D, 3, Width, Height, GL_RGB, GL_UNSIGNED_BYTE, pData);
//  glTexImage2D(GL_TEXTURE_2D, 0, 3, Width, Height, 0, GL_RGB, GL_UNSIGNED_BYTE, pData);  // Use when not wanting mipmaps to be built by openGL

  result :=Texture;
end;


{------------------------------------------------------------------}
{  Load BMP textures from the app resource                         }
{------------------------------------------------------------------}
function LoadResTexture(ResFilename: String; var Texture : GLuint) : Boolean;
var
  InfoHeader : TBitmapInfoHeader;
  // Palette    : Pointer;
  pData      : Pointer;
  BitmapLength  : Longint;
  PaletteLength : Longint;
  Width, Height : Integer;
  Buff          : array[0..MAX_PATH] of char;
  rsrc          : HRSRC;
  global        : HGLOBAL;
  resptr        : PChar;
begin
  result := FALSE;

  rsrc := FindResource(hInstance, StrPCopy(Buff, copy(ResFilename, 1, Pos('.', ResFilename)-1)), 'BMP');
  if rsrc = 0 then
  begin
    MessageBox(0, StrPCopy(Buff, 'File not found in resource - ' + ResFilename), PChar('BMP Texture'), MB_OK);
    Exit;
  end;

  global := LoadResource(hInstance, rsrc);
  if global = 0 then
  begin
    MessageBox(0, StrPCopy(Buff, 'Unable to read from resource - ' + ResFilename), PChar('BMP Unit'), MB_OK);
    Exit;
  end;

  resptr := LockResource(global);

  Move((PChar(resptr) + SizeOf(TBitmapFileHeader))^, InfoHeader, SizeOf(TBitmapInfoHeader));
  PaletteLength := InfoHeader.biClrUsed;
  // Palette := Pointer(PChar(resptr) + SizeOf(TBitmapFileHeader) + SizeOf(TBitmapInfoHeader));

  Width  := InfoHeader.biWidth;
  Height := InfoHeader.biHeight;

  BitmapLength := InfoHeader.biSizeImage;
  if BitmapLength = 0 then
    BitmapLength := Width * Height * InfoHeader.biBitCount Div 8;

  pData := Pointer(resptr + SizeOf(TBitmapFileHeader) + SizeOf(TBitmapInfoHeader) + PaletteLength);

  // Bitmaps are stored BGR and not RGB, so swap the R and B bytes.
//  SwapRGB(pData, Width*Height);

  Texture :=CreateTexture(Width, Height, GL_RGB, pData);
  result :=TRUE;
end;


end.
