<cfscript>
    bg = "ffffff";
    function getImg(d, waveA, oneA, roundedCorners, fg) {
        wave = fg & waveA;
        one = fg & oneA;
        var img = roundedCorners ? imageNew("", d, d, "argb") : imageNew("", d, d, "rgb", bg);
        imageSetAntialiasing(img, "on");

        if (roundedCorners) {
            imageSetDrawingColor(img, bg);
            var r = isNumeric(roundedCorners) ? roundedCorners : (d / 8);
            imageDrawRoundRect(img, 0, 0, d - 1, d - 1, r, r, true);
        }

        var br = d / 2 * sqr(2);
        var t = d - (d - br) / 2;
        var l = d / 2;

        var r = br / 16 * 15;
        imageSetDrawingColor(img, wave);
        imageDrawArc(img, l - r, t - r, r * 2, r * 2, 45, 90, "yes");

        r = br / 16 * 12;
        imageSetDrawingColor(img, bg);
        imageDrawArc(img, l - r, t - r, r * 2, r * 2, 30, 120, "yes");

        r = br / 16 * 9;
        imageSetDrawingColor(img, wave);
        imageDrawArc(img, l - r, t - r, r * 2, r * 2, 45, 90, "yes");

        r = br / 16 * 6;
        imageSetDrawingColor(img, bg);
        imageDrawArc(img, l - r, t - r, r * 2, r * 2, 30, 120, "yes");

        r = br / 16 * 3;
        imageSetDrawingColor(img, wave);
        imageDrawArc(img, l - r, t - r, r * 2, r * 2, 45, 90, "yes");

        imageSetDrawingColor(img, one);
        imageDrawText(img, "1", d * 0.182, d * 0.9, {
            font = "Times",
            size = d * 1.25
        });
        return img;
    }

    fg = "6aba45";
    dir = getDirectoryFromPath(getCurrentTemplatePath());
    imageWrite(getImg(512, "33", "bb", true, fg), "#dir#/logo.png");
    imageWrite(getImg(152, "33", "bb", false, fg), "#dir#/touch-icon.png");
    imageWrite(getImg( 32, "66", "ee", 12, "4a9543"), "#dir#/favicon.png");
</cfscript>
<cfdirectory action="list"
    directory="#dir#"
    filter="*.png"
    name="files"
    sort="size" />
<cfoutput>
<html>
<head>
    <link rel="icon" type="image/png" sizes="16x16" href="favicon.png" />
    <style>
        body { background-color: ##eeeef0 }
    </style>
</head>
<body>
<cfloop query="files">
    <img src="#name#" />
</cfloop>
</body>
</html>
</cfoutput>