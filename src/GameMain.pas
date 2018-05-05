program GameMain;
uses SwinGame, sgTypes, math;

type
    AlbumImage = record
        imgLocX, imgLocY : Integer;
        rectLocX, rectLocY : Integer;
        rectWidth, rectHeight : Integer;
        rectColor : Color;
        image : Bitmap;
    end;
    AlbumImageArray = Array of AlbumImage;
    MenuLocation = (MainMenu, AlbumMenu);

    UIButton = record
        rectLocX, rectLocY : Integer;
        rectWidth, rectHeight : Integer;
        rectColor, outlineColor : Color;
        labelText : String;
    end;

procedure DrawAlbumImage(_img : AlbumImage);
begin
    FillRectangle(_img.rectColor, _img.rectLocX, _img.rectLocY, _img.rectWidth, _img.rectHeight);
    DrawBitmap(_img.image, _img.imgLocX, _img.imgLocY);
end;

procedure DrawUIButton(_btn : UIButton);
var
    textX, textY : Integer;
begin
    FillRectangle(_btn.outlineColor, _btn.rectLocX - 5, _btn.rectLocY - 1, _btn.rectWidth + 6, _btn.rectHeight + 2);
    FillRectangle(_btn.rectColor, _btn.rectLocX, _btn.rectLocY, _btn.rectWidth, _btn.rectHeight);

    // Positioning text is... weird. I guess this works though
    textX := Floor((_btn.rectLocX + (_btn.rectLocX + _btn.rectWidth)) / 2) - Floor((_btn.rectWidth / 15));
    textY := Floor((_btn.rectLocY + (_btn.rectLocY + _btn.rectHeight)) / 2) - Floor((_btn.rectWidth / 15));
    DrawText(_btn.labelText, _btn.outlineColor, textX, textY);
end;

// This procedure is most important when we want to make an album look "deselected"
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

// This is mostly used for initialisation purposes
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

function CheckButtonIsHovered(_btn : UIButton) : Boolean;
begin
    result := PointInRect
    (
        MouseX(), MouseY(),
        _btn.rectLocX, _btn.rectLocY,
        _btn.rectWidth, _btn.rectHeight
    );
end;

// Load all the assets into the program before we continue. MUST BE CALLED FIRST THING!
procedure LoadAssets(var albumImages : AlbumImageArray; var backButton : UIButton);
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

    // UI Buttons
    backButton.rectLocX := 550;
    backButton.rectLocY := 600;
    backButton.rectWidth := 80;
    backButton.rectHeight := 30;
    backButton.rectColor := ColorGrey;
    backButton.outlineColor := ColorBlack;
    backButton.labelText := 'Back';
end;

// Handle all drawing for the main menu here
procedure DrawMainMenu(albumImages : AlbumImageArray; albumSelection : Integer);
var
    i : Integer;
    infoText : String;
begin
    // Show the user if they have hovered over an album and are able to click it
    if albumSelection >= 0 then
    begin
        albumImages[albumSelection].rectColor := ColorGrey;
    end
    else
    begin
        ResetAlbumRectColours(albumImages);
    end;

    // Display all albums
    i := 0;
    while i <= (High(albumImages)) do
    begin
        DrawAlbumImage(albumImages[i]);
        i += 1;
    end;
    DrawText('playing music is my passion.', ColorBlack, 450, 650);

    // Display information on any album that has been hovered over
    infoText := 'Hover over an album for more info';
    case albumSelection of
        0 : infoText := 'SATURATION - BROCKHAMPTON';
        1 : infoText := 'don''t smile at me - Billie Eilish';
        2 : infoText := 'Vessels - Starset';
        3 : infoText := 'Who Bit the Moon - David Maxim Micic';
    end;
    DrawText(infoText, ColorBlack, 10, 500);
end;

// Handle all inputs for the main menu here
procedure CheckMainMenuInput(albImgs : AlbumImageArray; var albumSelection : Integer; var currentMenu : MenuLocation);
var
    i : Integer;
begin
    albumSelection := -1;
    i := 0;
    while i <= High(albImgs) do
    begin
        // Check to see if there is an album being hovered over
        if PointInRect
        (
            MouseX(), MouseY(),
            albImgs[i].rectLocX, albImgs[i].rectLocY,
            albImgs[i].rectWidth, albImgs[i].rectHeight
        ) then albumSelection := i;

        // Check if the album that is being hovered over has been clicked
        if (albumSelection >= 0) and (MouseClicked(LeftButton)) then currentMenu := AlbumMenu;

        i += 1;
    end;
end;

// Handle all drawing for the album menu here
procedure DrawAlbumMenu(backButton : UIButton);
begin
    DrawUIButton(backButton);
end;

// Handle all the inputs for the album menu here
procedure CheckAlbumMenuInput(var currentMenu : MenuLocation; var backButton : UIButton);
begin
    if CheckButtonIsHovered(backButton) then backButton.outlineColor := ColorLightGrey
    else backButton.outlineColor := ColorBlack;
    if (CheckButtonIsHovered(backButton)) and (MouseClicked(LeftButton)) then currentMenu := MainMenu;
end;

procedure Main();
var
    // Universal
    albumImages : AlbumImageArray;
    albumSelection : Integer;
    currentMenu : MenuLocation;
    // Album Menu
    backButton : UIButton;
begin
    OpenGraphicsWindow('playing music is my passion', 700, 700);
    LoadAssets(albumImages, backButton);
    currentMenu := MainMenu;
    
    repeat // The game loop...
        ProcessEvents();
        ClearScreen(ColorWhite);
        // Start drawing everyting
        if currentMenu = MainMenu then
        begin
            CheckMainMenuInput(albumImages, albumSelection, currentMenu);
            DrawMainMenu(albumImages, albumSelection);
        end
        else if currentMenu = AlbumMenu then
        begin
            CheckAlbumMenuInput(currentMenu, backButton);
            DrawAlbumMenu(backButton);
        end;
        
        RefreshScreen(60);
    until WindowCloseRequested();
end;

begin
    Main();
end.
