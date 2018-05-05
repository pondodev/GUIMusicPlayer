program GameMain;
uses SwinGame, sgTypes, math, sysutils;

type
    AlbumImage = record
        imgLocX, imgLocY : Integer;
        rectLocX, rectLocY : Integer;
        rectWidth, rectHeight : Integer;
        rectColor : Color;
        image : Bitmap;
    end;

    MenuLocation = (MainMenu, AlbumMenu);

    UIButton = record
        rectLocX, rectLocY : Integer;
        rectWidth, rectHeight : Integer;
        rectColor, outlineColor : Color;
        labelText : String;
    end;

    Track = record
        name, path : String;
    end;
    TrackArray = Array of Track;
    MusicGenre = (ProgMetal, HipHop, Rock, Electropop);
    Album = record
        name, artist, path : String;
        genre : MusicGenre;
        trackCount : Integer;
        tracks : TrackArray;
        albumArt : AlbumImage;
    end;
    AlbumArray = Array of Album;

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
procedure ResetAlbumRectColours(var userAlbums : AlbumArray);
var
    i : Integer;
begin
    i := 0;
    while i <= High(userAlbums) do
    begin
        userAlbums[i].albumArt.rectColor := ColorBlack;
        i += 1;
    end;
end;

// This is mostly used for initialisation purposes
procedure ResetAlbumRectWidthHeight(var userAlbums : AlbumArray);
var
    i : Integer;
begin
    i := 0;
    while i <= High(userAlbums) do
    begin
        userAlbums[i].albumArt.rectWidth := 206;
        userAlbums[i].albumArt.rectHeight := 202;
        i += 1;
    end;
end;

function SetAlbumImagePosition(albImg : AlbumImage; locX, locY : Integer) : AlbumImage;
begin
    albImg.imgLocX := locX;
    albImg.imgLocY := locY;
    albImg.rectLocX := locX - 5;
    albImg.rectLocY := locY - 1;
    result := albImg;
end;

procedure ResetAlbumImageDefaults(var userAlbums : AlbumArray);
begin
    userAlbums[0].albumArt.imgLocX := 15;
    userAlbums[0].albumArt.imgLocY := 10;
    userAlbums[0].albumArt.rectLocX := 10;
    userAlbums[0].albumArt.rectLocY := 9;

    userAlbums[1].albumArt.imgLocX := userAlbums[0].albumArt.imgLocX + 230;
    userAlbums[1].albumArt.imgLocY := userAlbums[0].albumArt.imgLocY;
    userAlbums[1].albumArt.rectLocX := userAlbums[0].albumArt.rectLocX + 230;
    userAlbums[1].albumArt.rectLocY := userAlbums[0].albumArt.rectLocY;

    userAlbums[2].albumArt.imgLocX := userAlbums[0].albumArt.imgLocX;
    userAlbums[2].albumArt.imgLocY := userAlbums[0].albumArt.imgLocY + 225;
    userAlbums[2].albumArt.rectLocX := userAlbums[0].albumArt.rectLocX;
    userAlbums[2].albumArt.rectLocY := userAlbums[0].albumArt.rectLocY + 225;

    userAlbums[3].albumArt.imgLocX := userAlbums[2].albumArt.imgLocX + 230;
    userAlbums[3].albumArt.imgLocY := userAlbums[2].albumArt.imgLocY;
    userAlbums[3].albumArt.rectLocX := userAlbums[2].albumArt.rectLocX + 230;
    userAlbums[3].albumArt.rectLocY := userAlbums[2].albumArt.rectLocY;
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
procedure LoadAssets(var userAlbums : AlbumArray; var backButton : UIButton);
var
    tempString : String;
    albumDataFile : TextFile;
    i, a : Integer;
begin
    SetLength(userAlbums, 4);

    // Load images
    userAlbums[0].albumArt.image := LoadBitmap('whobitthemoon.jpg');
    userAlbums[1].albumArt.image := LoadBitmap('saturation.jpg');
    userAlbums[2].albumArt.image := LoadBitmap('vessels.jpg');
    userAlbums[3].albumArt.image := LoadBitmap('dontsmileatme.jpg');

    ResetAlbumImageDefaults(userAlbums);

    // Set generic values
    ResetAlbumRectColours(userAlbums);
    ResetAlbumRectWidthHeight(userAlbums);

    // Prepare album data file for reading
    AssignFile(albumDataFile, 'albums.dat');
    Reset(albumDataFile);

    // Iterate through each album and assign relevant info
    i := 0;
    while i <= High(userAlbums) do
    begin
        ReadLn(albumDataFile, userAlbums[i].name);
        ReadLn(albumDataFile, userAlbums[i].artist);
        ReadLn(albumDataFile, tempString);
        userAlbums[i].genre := MusicGenre(StrToInt(tempString));
        ReadLn(albumDataFile, tempString);
        userAlbums[i].trackCount := StrToInt(tempString);
        ReadLn(albumDataFile, userAlbums[i].path);

        // Loop through to add all tracks
        a := 0;
        SetLength(userAlbums[i].tracks, userAlbums[i].trackCount);
        while a < userAlbums[i].trackCount do
        begin
            ReadLn(albumDataFile, userAlbums[i].tracks[a].name);
            ReadLn(albumDataFile, userAlbums[i].tracks[a].path);
            a += 1;
        end;

        i +=1;
    end;
    Close(albumDataFile); // Close file once we're done with it

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
procedure DrawMainMenu(userAlbums : AlbumArray; albumSelection : Integer);
var
    i : Integer;
    infoText : String;
begin
    // Show the user if they have hovered over an album and are able to click it
    if albumSelection >= 0 then
    begin
        userAlbums[albumSelection].albumArt.rectColor := ColorGrey;
    end
    else
    begin
        ResetAlbumRectColours(userAlbums);
    end;

    // Display all albums
    i := 0;
    while i <= (High(userAlbums)) do
    begin
        DrawAlbumImage(userAlbums[i].albumArt);
        i += 1;
    end;
    DrawText('playing music is my passion.', ColorBlack, 450, 650);

    // Display information on any album that has been hovered over
    if albumSelection >= 0 then
        infoText := userAlbums[albumSelection].name + ' - ' + userAlbums[albumSelection].artist
    else
        infoText := 'Select an album';

    DrawText(infoText, ColorBlack, 10, 500);
end;

// Handle all inputs for the main menu here
procedure CheckMainMenuInput(userAlbums : AlbumArray; var albumSelection : Integer; var currentMenu : MenuLocation);
var
    i : Integer;
begin
    albumSelection := -1;
    i := 0;
    while i <= High(userAlbums) do
    begin
        // Check to see if there is an album being hovered over
        if PointInRect
        (
            MouseX(), MouseY(),
            userAlbums[i].albumArt.rectLocX, userAlbums[i].albumArt.rectLocY,
            userAlbums[i].albumArt.rectWidth, userAlbums[i].albumArt.rectHeight
        ) then albumSelection := i;

        // Check if the album that is being hovered over has been clicked
        if (albumSelection >= 0) and (MouseClicked(LeftButton)) then currentMenu := AlbumMenu;

        i += 1;
    end;
end;

// Handle all drawing for the album menu here
procedure DrawAlbumMenu(backButton : UIButton; albImg : AlbumImage);
begin
    DrawUIButton(backButton);

    // Move the album image into the top left corner
    albImg := SetAlbumImagePosition(albImg, 15, 10);
    albImg.rectColor := ColorBlack;
    DrawAlbumImage(albImg);
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
    userAlbums : AlbumArray;
    albumSelection : Integer;
    currentMenu : MenuLocation;
    // Album Menu
    backButton : UIButton;
begin
    OpenGraphicsWindow('playing music is my passion', 700, 700);
    LoadAssets(userAlbums, backButton);
    currentMenu := MainMenu;
    
    repeat // The game loop...
        ProcessEvents();
        ClearScreen(ColorWhite);
        // Start drawing everyting
        if currentMenu = MainMenu then
        begin
            CheckMainMenuInput(userAlbums, albumSelection, currentMenu);
            DrawMainMenu(userAlbums, albumSelection);
        end
        else if currentMenu = AlbumMenu then
        begin
            CheckAlbumMenuInput(currentMenu, backButton);
            DrawAlbumMenu(backButton, userAlbums[albumSelection].albumArt);
        end;
        
        RefreshScreen(60);
    until WindowCloseRequested();
end;

begin
    Main();
end.
