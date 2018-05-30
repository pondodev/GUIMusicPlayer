program GameMain;
uses SwinGame, sgTypes, math, sysutils, Crt;

type
    AlbumImage = record
        imgLocX, imgLocY : Integer;
        rectLocX, rectLocY : Integer;
        rectWidth, rectHeight : Integer;
        rectColor : Color;
        imagePath : String;
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
        doot : Music;
    end;
    TrackArray = Array of Track;
    MusicGenre = (ProgMetal, Remix, Rock, Electropop);
    Album = record
        name, artist, path : String;
        genre : MusicGenre;
        trackCount : Integer;
        tracks : TrackArray;
        albumArt : AlbumImage;
    end;
    AlbumArray = Array of Album;

// It's easier to have these variables exit in a global scope since we may need them when
// using networked features
const
    CONN : Connection = nil;
    PORT : Integer = 4000;

// I seriously do not like how this locks up the ENTIRE program, but multi threaded 
procedure OpenHost();
begin
    CreateTCPHost(PORT);
    while CONN = nil do
    begin
        AcceptTCPConnection();
        CONN := FetchConnection();
    end;
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
    textX := _btn.rectLocX + 5;
    textY := Floor((_btn.rectLocY + (_btn.rectLocY + _btn.rectHeight)) / 2) - Floor((_btn.rectWidth / 20));
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

procedure ButtonHoverVisual(var _btn : UIButton);
begin
    if (CheckButtonIsHovered(_btn)) and (MouseDown(LeftButton)) then _btn.outlineColor := ColorPurple
    else if CheckButtonIsHovered(_btn) then _btn.outlineColor := ColorLightGrey
    else _btn.outlineColor := ColorBlack;
end;

function CreateUIButton(x, y, width, height : Integer; rectColor, outlineColor: Color; labelText : String) : UIButton;
begin
    result.rectLocX := x;
    result.rectLocY := y;
    result.rectWidth := width;
    result.rectHeight := height;
    result.rectColor := rectColor;
    result.outlineColor := outlineColor;
    result.labelText := labelText;
end;

// Load all the assets into the program before we continue. MUST BE CALLED FIRST THING!
procedure LoadAssets(var userAlbums : AlbumArray; var backButton, playAlbumButton, playButton, pauseButton, nextTrackButton, previousTrackButton, upButton, downButton, playTrackButton, startConnectionButton : UIButton);
var
    tempString : String;
    albumDataFile : TextFile;
    i, a : Integer;
begin
    SetLength(userAlbums, 4);

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
        ReadLn(albumDataFile, userAlbums[i].albumArt.imagePath);
        userAlbums[i].albumArt.image := LoadBitmap(userAlbums[i].albumArt.imagePath);
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
            userAlbums[i].tracks[a].doot := LoadMusic(userAlbums[i].path + userAlbums[i].tracks[a].path);
            a += 1;
        end;

        i +=1;
    end;
    Close(albumDataFile); // Close file once we're done with it
    
    ResetAlbumImageDefaults(userAlbums);

    // UI Buttons
    backButton := CreateUIButton(600, 450, 80, 30, ColorGrey, ColorBlack, 'Back');
    playAlbumButton := CreateUIButton(15, 350, 100, 30, ColorGrey, ColorBlack, 'Play Album');
    playButton := CreateUIButton(15, 390, 100, 20, ColorGrey, ColorBlack, 'Play');
    pauseButton := CreateUIButton
    (
        playButton.rectLocX, playButton.rectLocY,
        playButton.rectWidth, playButton.rectHeight,
        playButton.rectColor, playButton.outlineColor, 'Pause'
    );
    nextTrackButton := CreateUIButton(15, 420, 100, 20, ColorGrey, ColorBlack, 'Next');
    previousTrackButton := CreateUIButton(15, 450, 100, 20, ColorGrey, ColorBlack, 'Previous');
    upButton := CreateUIButton(530, 10, 40, 25, ColorGrey, ColorBlack, 'Up');
    downButton := CreateUIButton(580, 10, 40, 25, ColorGrey, ColorBlack, 'Down');
    playTrackButton := CreateUIButton(530, 40, 90, 25, ColorGrey, ColorBlack, 'Play Track');
    startConnectionButton := CreateUIButton(15, 450, 140, 20, ColorGrey, ColorBlack, 'Start Connection');
end;

// Handle all drawing for the main menu here
procedure DrawMainMenu(userAlbums : AlbumArray; albumSelection : Integer; startConnectionButton : UIButton);
var
    i : Integer;
    infoText : String;
begin
    DrawUIButton(startConnectionButton);

    // Show the user if they have hovered over an album and are able to click it
    if albumSelection >= 0 then
    begin
        if MouseDown(LeftButton) then userAlbums[albumSelection].albumart.rectColor := ColorPurple
        else userAlbums[albumSelection].albumArt.rectColor := ColorGrey;
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
    DrawText('playing music is my passion.', ColorBlack, 460, 480);

    // Display information on any album that has been hovered over
    if albumSelection >= 0 then
        infoText := userAlbums[albumSelection].name + ' - ' + userAlbums[albumSelection].artist
    else
        infoText := 'Select an album';

    DrawText(infoText, ColorBlack, 10, 480);
end;

// Handle all inputs for the main menu here
procedure CheckMainMenuInput(userAlbums : AlbumArray; var albumSelection : Integer; var currentMenu : MenuLocation; var startConnectionButton : UIButton);
var
    i : Integer;
begin
    ButtonHoverVisual(startConnectionButton);

    if (CheckButtonIsHovered(startConnectionButton)) and (MouseClicked(LeftButton)) then OpenHost();

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
procedure DrawAlbumMenu(backButton, playAlbumButton, playButton, pauseButton, nextTrackButton, previousTrackButton, upButton, downButton, playTrackButton : UIButton; userAlbum : Album; musicPaused : Boolean; currentTrack, userTrackSelection : Integer);
var
    tempString : String;
    i, trackTextLocY : Integer;
begin
    DrawUIButton(backButton);
    DrawUIButton(playAlbumButton);
    DrawUIButton(nextTrackButton);
    DrawUIButton(previousTrackButton);
    DrawUIButton(upButton);
    DrawUIButton(downButton);
    DrawUIButton(playTrackButton);
    if musicPaused then DrawUIButton(playButton)
    else DrawUIButton(pauseButton);

    // Move the album image into the top left corner
    userAlbum.albumArt := SetAlbumImagePosition(userAlbum.albumArt, 15, 10);
    userAlbum.albumArt.rectColor := ColorBlack;
    DrawAlbumImage(userAlbum.albumArt);

    // Draw all the related album info below the album
    DrawText('Album: ' + userAlbum.name, ColorBlack, 10, 225);
    DrawText('Artist: ' + userAlbum.artist, ColorBlack, 10, 240);
    Str(userAlbum.genre, tempString);
    DrawText('Genre: ' + tempString, ColorBlack, 10, 255);
    DrawText('Number of tracks: ' + IntToStr(userAlbum.trackCount), ColorBlack, 10, 270);

    // Draw what is now playing if music is playing
    if MusicPlaying() then
        DrawText('Now playing: ' + userAlbum.tracks[currentTrack - 1].name, RandomRGBColor(255), 10, 285);

    i := 0;
    trackTextLocY := 10;
    // Draw all the track names
    while i < userAlbum.trackCount do
    begin
        DrawText(IntToStr(i + 1) + '. ' + userAlbum.tracks[i].name, ColorBlack, 300, trackTextLocY);
        i += 1;
        trackTextLocY += 15;
    end;

    DrawText('>', ColorRed, 290, 10 + (userTrackSelection * 15));
end;

procedure PlayAlbum(userAlbum : Album; var currentTrack : Integer);
begin
    // Check if we have reached the end of the current song
    if (currentTrack >= 0) and (not MusicPlaying()) then
    begin
        // Check if we are at the end of the album
        if currentTrack = userAlbum.trackCount then currentTrack := -1
        else
        begin
            // Play song and set current track to the next song
            PlayMusic(userAlbum.tracks[currentTrack].doot, 1);
            currentTrack += 1;
        end;
    end;
end;

// Handle all the inputs for the album menu here
procedure CheckAlbumMenuInput(var currentMenu : MenuLocation; var currentTrack, userTrackSelection: Integer; var musicPaused : Boolean; userAlbum : Album; var backButton, playAlbumButton, playButton, pauseButton, nextTrackButton, previousTrackButton, upButton, downButton, playTrackButton : UIButton);
begin
    ButtonHoverVisual(backButton);
    ButtonHoverVisual(playAlbumButton);
    ButtonHoverVisual(playButton);
    ButtonHoverVisual(pauseButton);
    ButtonHoverVisual(nextTrackButton);
    ButtonHoverVisual(previousTrackButton);
    ButtonHoverVisual(upButton);
    ButtonHoverVisual(downButton);
    ButtonHoverVisual(playTrackButton);

    // Check if we're clicking on any of the UI buttons
    if (CheckButtonIsHovered(backButton)) and (MouseClicked(LeftButton)) then currentMenu := MainMenu;
    if (CheckButtonIsHovered(playAlbumButton)) and (MouseClicked(LeftButton)) and (currentTrack = -1) then currentTrack := 0;

    // Play/pause music functionality
    if musicPaused then
    begin
        if (CheckButtonIsHovered(playButton)) and (MouseClicked(LeftButton)) then musicPaused := false;
        PauseMusic();
    end
    else
    begin
        if (CheckButtonIsHovered(pauseButton)) and (MouseClicked(LeftButton)) then musicPaused := true;
        ResumeMusic();
    end;

    // NOTE: Both moving forwards or backwards out of the bounds of the album will
    //       force the program to stop all music playback
    // Move forward one track
    if (CheckButtonIsHovered(nextTrackButton)) and (MouseClicked(LeftButton)) then
    begin
        if currentTrack = userAlbum.trackCount then
        begin
            currentTrack := -1;
            StopMusic();
        end
        else if currentTrack = -1 then
        begin
            currentTrack := 0;
        end
        else
        begin
            PlayMusic(userAlbum.tracks[currentTrack].doot, 1);
            currentTrack += 1;
        end;
    end;

    // Move backwards one track
    if (CheckButtonIsHovered(previousTrackButton)) and (MouseClicked(LeftButton)) then
    begin
        if currentTrack = 1 then
        begin
            currentTrack := -1;
            StopMusic();
        end
        else if currentTrack > 1 then
        begin
            currentTrack -= 2;
            PlayMusic(userAlbum.tracks[currentTrack].doot, 1);
            currentTrack += 1;
        end;
    end;

    // User track selection
    if (CheckButtonIsHovered(upButton)) and (MouseClicked(LeftButton)) then userTrackSelection -=1;
    if (CheckButtonIsHovered(downButton)) and (MouseClicked(Leftbutton)) then userTrackSelection += 1;
    if userTrackSelection = userAlbum.trackCount then userTrackSelection := 0
    else if userTrackSelection = -1 then userTrackSelection := userAlbum.trackCount - 1;

    // Play user track selection
    if (CheckButtonIsHovered(playTrackButton)) and (MouseClicked(LeftButton)) then
    begin
        StopMusic();
        currentTrack := userTrackSelection;
        musicPaused := false;
    end;

    // Check if we've set up to play any tracks
    if (currentTrack >= 0) and (not musicPaused) then PlayAlbum(userAlbum, currentTrack);
end;

procedure Main();
var
    // Universal
    userAlbums : AlbumArray;
    albumSelection, i, a : Integer;
    currentMenu : MenuLocation;
    // Album Menu
    backButton, playAlbumButton, playButton, pauseButton, nextTrackButton, previousTrackButton, upButton, downButton, playTrackButton, startConnectionButton : UIButton;
    currentTrack, userTrackSelection : Integer;
    musicPaused : Boolean;
begin
    OpenGraphicsWindow('playing music is my passion', 700, 500);

    // Initialise assets and variables
    LoadAssets(userAlbums, backButton, playAlbumButton, playButton, pauseButton, nextTrackButton, previousTrackButton, upButton, downButton, playTrackButton, startConnectionButton);
    OpenAudio();
    currentMenu := MainMenu;
    albumSelection := 0;
    
    repeat // The game loop...
        ProcessEvents();
        ClearScreen(ColorWhite);
        // Start drawing everyting
        if currentMenu = MainMenu then
        begin
            // We need to stop the music and set currentTrack to -1 so we reset all playback
            StopMusic();
            currentTrack := -1;
            musicPaused := false;
            userTrackSelection := 0;
            CheckMainMenuInput(userAlbums, albumSelection, currentMenu, startConnectionButton);
            DrawMainMenu(userAlbums, albumSelection, startConnectionButton);
        end
        else if currentMenu = AlbumMenu then
        begin
            CheckAlbumMenuInput(currentMenu, currentTrack, userTrackSelection, musicPaused, userAlbums[albumSelection], backButton, playAlbumButton, playButton, pauseButton, nextTrackButton, previousTrackButton, upButton, downButton, playTrackButton);
            DrawAlbumMenu(backButton, playAlbumButton, playButton, pauseButton, nextTrackButton, previousTrackButton, upButton, downButton, playTrackButton, userAlbums[albumSelection], musicPaused, currentTrack, userTrackSelection);
        end;
        
        RefreshScreen(60);
    until WindowCloseRequested();

    // Release all assets before exiting
    CloseAudio();

    i := 0;
    a := 0;
    while i <= High(userAlbums) do
    begin
        while a < userAlbums[i].trackCount do
        begin
            FreeMusic(userAlbums[i].tracks[a].doot);
            a += 1;
        end;
        i += 1;
    end;

    i := 0;
    while i <= High(userAlbums) do
    begin
        FreeBitmap(userAlbums[i].albumArt.image);
        i += 1;
    end;
end;

begin
    Main();
end.
