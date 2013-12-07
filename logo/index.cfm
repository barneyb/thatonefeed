<cfscript>
    feedly = "6aba45";
    bg = "000000";
    function getImg(d, waveA, oneA, roundedCorners) {
        wave = feedly & waveA;
        one = feedly & oneA;
        var img = imageNew("", d, d, "argb", roundedCorners ? "ffffff" : bg);
        imageSetAntialiasing(img, "on");

        if (roundedCorners) {
            imageSetDrawingColor(img, bg);
            var r = isNumeric(roundedCorners) ? roundedCorners : (d / 8);
            writeDump(r);
            imageDrawRoundRect(img, 0, 0, d - 1, d - 1, r, r, true);
        }

        var br = d / 2 * sqr(2);
        var t = d - (d - br) / 1.5;
        var l = d / 2;

        var r = br / 16 * 15;
        imageSetDrawingColor(img, wave);
        imageDrawArc(img, l - r, t - r, r * 2, r * 2, 45, 90, "yes");

        r = br / 16 * 12;
        imageSetDrawingColor(img, bg);
        imageDrawArc(img, l - r, t - r, r * 2, r * 2, 45, 90, "yes");

        r = br / 16 * 9;
        imageSetDrawingColor(img, wave);
        imageDrawArc(img, l - r, t - r, r * 2, r * 2, 45, 90, "yes");

        r = br / 16 * 6;
        imageSetDrawingColor(img, bg);
        imageDrawArc(img, l - r, t - r, r * 2, r * 2, 45, 90, "yes");

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

    dir = getDirectoryFromPath(getCurrentTemplatePath());
    imageWrite(getImg(512, "33", "99", true), "#dir#/logo.png");
    imageWrite(getImg(152, "33", "aa", false), "#dir#/touch-icon.png");
    imageWrite(getImg( 16, "99", "ff", 10), "#dir#/favicon.png");
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
</head>
<body>
<cfloop query="files">
    <img src="#name#" />
</cfloop>
</body>
</html>
</cfoutput>