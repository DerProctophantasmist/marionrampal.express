config = 
    baseUrlDefault: "https://www.marionrampal.com"
    baseUrlFr: "https://fr.marionrampal.com"
    baseUrlEn: "https://en.marionrampal.com"
    bannerTitle: "Marion Rampal"
    compileDate: "20220216" #forces redownloading of assets by client when changed
    "mainPage": 
        "description": 
            "fr": "Marion Rampal, chanteuse et songwriter. Actualités, concerts, disques…"
            "en": "Marion Rampal, singer and songwriter. News, concerts, albums…"
        "websiteTitle": 
            "fr": "Site officiel de Marion Rampal"
            "en": "Official website of Marion Rampal"
        image: "https://marionrampal.com/images/MarionRampal.MarieRouge.dorée.sourire.right.jpg"
        footer:"<small><li>&copy; Marion Rampal</li><li>Artwork on Main Blue: Marc Hernandez</li><li>Original photos: <a href='http://marierouge.fr/'>Marie Rouge</a>, Martin Sarrazac</li><li>Design and Implementation: Martin Sarrazac with a kickstart from <a href='http://html5up.net'>HTML5 UP</a></li></small>"
    "prodPublicDir" : "/home/marion/public_html",
    "stagingPublicDir" : "/home/marion/public_html/staging"
    entryFile:"sections.md"
    contact: 
        origin: /https?:\/\/([^.]+\.)*marionrampal.(com|local)/
        mailerKeyFile: 'keys/mailer.marionrampal.com.json'
        mailTo: 'marionrampal.hotmail.com;m.sarrazac@gmail.com'
    
module.exports = config