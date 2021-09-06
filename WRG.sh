#!/bin/bash
if [ "$1" = "" ]
then
echo "no steam ID supplied"
exit 0
fi
#test https://steamcommunity.com/id/$1/games    if failed exit with error
if curl -s https://steamcommunity.com/id/$1/games | grep "The specified profile could not be found"; then echo "Steam profile not found"; exit 0; fi
if ! curl -s https://steamcommunity.com/id/$1/games; then echo "Can't access Steam library, make sure to have it visible to public in the privacy settings"; exit 0; fi

#test https://www.speedrun.com/api/v1           if failed exit with error
if ! curl -s https://www.speedrun.com/api/v1 | grep "regions"; then echo "Can't reach speedrun.com"; exit 0; fi

#get and format a list of all games in Steam library
curl -s https://steamcommunity.com/id/$1/games/?tab=all | grep "var rgGames =" | sed 's/,/\n/g' | grep '"name"' | sed 's/"name":"\|"//g' | sed 's/ /_/g'> /tmp/speedgamesfile

#read games list into a while loop
while read gameName; do
        echo "Searching for "$gameName
#get the ammount of results found for a game name search
        gamecount=$(curl -s https://www.speedrun.com/api/v1/games?name=$gameName | sed 's/,/\n/g' | grep names | sed 's/":"\|international\|names\|"\|:{//g' | wc -l); sleep 0.3 #put a sleep 0.3 on to not stress out SR.C servers
        echo $gamecount "Game(s) found"
#if no games were found skip trying to find categories and records for it
        if [ $gamecount -eq 0 ]
        then
                sleep 1 #could remove this, but makes it go by too fast
                echo ""
                continue
        fi
#display the list of the found games in the search
        curl -s https://www.speedrun.com/api/v1/games?name=$gameName | sed 's/,/\n/g' | grep names | sed 's/":"\|international\|names\|"\|:{//g'; sleep 0.3
        echo ""
#get the gameid for said game. picking the first one cus that is most likely to match the search term from the SteamLibraryFile
        gameId=$(curl -s https://www.speedrun.com/api/v1/games?name=$gameName | sed 's/,/\n/g' | grep '"id"' | sed 's/"id"\|"data"\|"\|{\|:\|\[//g' | head -n1); sleep 0.3
        echo "Using game with ID: "$gameId
#display the categories count and name
        echo -e $(curl -s https://www.speedrun.com/api/v1/games/$gameId/categories | jq | grep '"name"' | sed 's/"\|,\|^[ \t]*\|name\|: //g' | wc -l) "Categorie(s) found\n"; sleep 0.3
#put categories ID into a file to be read by while loop later
        curl -s https://www.speedrun.com/api/v1/games/$gameId/categories | jq | grep '"id"' | sed 's/^[ \t]*"id": \|"\|,//g' > /tmp/speedcategoriesfile; sleep 0.3
        x=1
#while loop that reads categories ID and gets the current WorldRecord time
        while read catId; do
                echo "WR for category "$(curl -s https://www.speedrun.com/api/v1/games/$gameId/categories | jq | grep '"name"' | sed 's/"\|,\|^[ \t]*\|name\|: //g' | head -n$x | tail -n1)" in "$gameName" is: "$(curl -s https://www.speedrun.com/api/v1/categories/$catId/records | jq | grep '"primary"' | head -n 1 | sed 's/^[ \t]*"primary": \|"\|,\|PT//g' | sed 's/H/H /g' | sed 's/M/M /g'); sleep 0.3
                x=$(($x+1))
        done < /tmp/speedcategoriesfile
        echo ""
        sleep 0.3 #sleep again to avoid stressing the SR.C servers
done < /tmp/speedgamesfile
#TODO:
#remove the files used / cleanup after your self
#better error handeling
#something to store the curls localy so it dont have to send a request so often
#
