program GameMain;
uses SwinGame, sgTypes;

type
    AlbumImage = record
        imgLocX, imgLocY : Integer;
        rectLocX, rectLocY : Integer;
        rectWidth, rectHeight : Integer;
        rectColor : Color;
        image : Bitmap;
    end;
    AlbumImageArray = Array of AlbumImage;

procedure DrawAlbumImage(_img : AlbumImage);
begin
    FillRectangle(_img.rectColor, _img.rectLocX, _img.rectLocY, _img.rectWidth, _img.rectHeight);
    DrawBitmap(_img.image, _img.imgLocX, _img.imgLocY);
end;

procedure ResetAlbumRectColours(var albumImages : AlbumImageArray);
var
    i : Integer;
begin
    i := 0;
    while i <= High(albumImages) do
    begin
        albumImages[i].rectColor := ColorBlack;
        i += 1;
    end;
end;

procedure ResetAlbumRectWidthHeight(var albumImages : AlbumImageArray);
var
    i : Integer;
begin
    i := 0;
    while i <= High(albumImages) do
    begin
        albumImages[i].rectWidth := 206;
        albumImages[i].rectHeight := 202;
        i += 1;
    end;
end;

procedure DrawMainMenu(albumImages : AlbumImageArray; albumHoveredIndex : Integer);
var
    i : Integer;
    infoText : String;
begin
    if albumHoveredIndex >= 0 then
    begin
        albumImages[albumHoveredIndex].rectColor := ColorGrey;
    end
    else
    begin
        ResetAlbumRectColours(albumImages);
    end;

    i := 0;
    while i <= (High(albumImages)) do
    begin
        DrawAlbumImage(albumImages[i]);
        i += 1;
    end;
    DrawText('playing music is my passion.', ColorBlack, 450, 650);
    infoText := 'Hover over an album for more info';

    case albumHoveredIndex of
        0 : infoText := 'SATURATION - BROCKHAMPTON';
        1 : infoText := 'don''t smile at me - Billie Eilish';
        2 : infoText := 'Vessels - Starset';
        3 : infoText := 'Who Bit the Moon - David Maxim Micic';
    end;
    
    DrawText(infoText, ColorBlack, 10, 500);
end;

procedure LoadAssets(var albumImages : AlbumImageArray);
begin
    SetLength(albumImages, 4);

    // Load Saturation
    albumImages[0].imgLocX := 15;
    albumImages[0].imgLocY := 10;
    albumImages[0].rectLocX := 10;
    albumImages[0].rectLocY := 9;
    albumImages[0].image := LoadBitmap('saturation.jpg');

    // Load don't smile at me
    albumImages[1].imgLocX := albumImages[0].imgLocX + 230;
    albumImages[1].imgLocY := albumImages[0].imgLocY;
    albumImages[1].rectLocX := albumImages[0].rectLocX + 230;
    albumImages[1].rectLocY := albumImages[0].rectLocY;
    albumImages[1].image := LoadBitmap('dontsmileatme.jpg');

    // Load Vessels
    albumImages[2].imgLocX := albumImages[0].imgLocX;
    albumImages[2].imgLocY := albumImages[0].imgLocY + 225;
    albumImages[2].rectLocX := albumImages[0].rectLocX;
    albumImages[2].rectLocY := albumImages[0].rectLocY + 225;
    albumImages[2].image := LoadBitmap('vessels.jpg');

    // Load Who Bit the Moon
    albumImages[3].imgLocX := albumImages[2].imgLocX + 230;
    albumImages[3].imgLocY := albumImages[2].imgLocY;
    albumImages[3].rectLocX := albumImages[2].rectLocX + 230;
    albumImages[3].rectLocY := albumImages[2].rectLocY;
    albumImages[3].image := LoadBitmap('whobitthemoon.jpg');

    // Set generic values
    ResetAlbumRectColours(albumImages);
    ResetAlbumRectWidthHeight(albumImages);
end;

procedure CheckMainMenuInput(albImgs : AlbumImageArray; var albumHoveredIndex : Integer);
var
    i : Integer;
begin
    albumHoveredIndex := -1;
    i := 0;
    while i <= High(albImgs) do
    begin
        if PointInRect
        (
            MouseX(), MouseY(),
            albImgs[i].rectLocX, albImgs[i].rectLocY,
            albImgs[i].rectWidth, albImgs[i].rectHeight
        ) then albumHoveredIndex := i;

        i += 1;
    end;
end;

procedure Main();
var
    albumImages : AlbumImageArray;
    albumHoveredIndex : Integer;
begin
    OpenGraphicsWindow('playing music is my passion', 700, 700);
    LoadAssets(albumImages);
    
    repeat // The game loop...
        ProcessEvents();
        ClearScreen(ColorWhite);
        // Start drawing everyting
        CheckMainMenuInput(albumImages, albumHoveredIndex);
        DrawMainMenu(albumImages, albumHoveredIndex);
        
        RefreshScreen(60);
    until WindowCloseRequested();
end;

begin
    Main();
end.
