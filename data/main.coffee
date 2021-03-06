config = 
    baseUrlDefault: "http://www.marionrampal.com"
    baseUrlFr: "http://fr.marionrampal.com"
    baseUrlEn: "http://en.marionrampal.com"
    title: "Marion Rampal"
    "mainPage": 
        "description": 
            "fr": "Marion Rampal, chanteuse et songwriter. Actualités, concerts, disques…"
            "en": "Marion Rampal, singer and songwriter. News, concerts, albums…"
        image: "http://marionrampal.com/images/MarionRampal.MainBlue.clindoeil.jpg"
        footer:"<small><li>&copy; Marion Rampal</li><li>Artwork on Main Blue: Marc Hernandez</li><li>Original photos: <a href='http://marierouge.fr/'>Marie Rouge</a>, Martin Sarrazac</li><li>Design and Implementation: Martin Sarrazac with a kickstart from <a href='http://html5up.net'>HTML5 UP</a></li></small>"
    "prodPublicDir" : "/home/marion/public_html",
    "stagingPublicDir" : "/home/marion/public_html/staging"
    contact: 
        origin: /http:\/\/([^.]+\.)*marionrampal.(com|local)/
        mailerKeyFile: 'keys/mailer.marionrampal.com.json'
        mailTo: 'marionrampal@hotmail.com'
    
module.exports = config