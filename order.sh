#!/bin/bash

userAgent="User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:9.0.1) Gecko/20100101 Firefox/9.0.1"

cookie="JSESSIONID=31F53E0367648074F98328EBA423C34A; BIGipServerotsweb=3002532106.36895.0000"

referer="https://dynamic.12306.cn/otsweb/order/confirmPassengerAction.do?method=init"

trainDate="2012-01-20"
trainNoLong="5l0000G22202"
trainNo="G222"
fromStationCode="AOH"
fromStationName="%E4%B8%8A%E6%B5%B7%E8%99%B9%E6%A1%A5"
toStationCode="UUH"
toStationName="%E5%BE%90%E5%B7%9E%E4%B8%9C"
startTime="07%3A05"
endTime="09%3A42"
seatType="O" # O 二等座   M 一等座   P 特等座   1 硬座   3 硬卧   4 软卧
passengerName="%E6%9D%8E"
passengerId="110102198008012816"
passengerMobile="13818883164"
verifyCode="pe3p"
realToken=""

echo $(date +"%T") Initilized
while [ 1 ]
do
    echo $(date +"%T") Begin send request
    postData="org.apache.struts.taglib.html.TOKEN="$realToken"&textfield=%E4%B8%AD%E6%96%87%E6%88%96%E6%8B%BC%E9%9F%B3%E9%A6%96%E5%AD%97%E6%AF%8D&checkbox2=2&orderRequest.train_date="$trainDate"&orderRequest.train_no="$trainNoLong"&orderRequest.station_train_code="$trainNo"&orderRequest.from_station_telecode="$fromStationCode"&orderRequest.to_station_telecode="$toStationCode"&orderRequest.seat_type_code=&orderRequest.ticket_type_order_num=&orderRequest.bed_level_order_num=000000000000000000000000000000&orderRequest.start_time="$startTime"&orderRequest.end_time="$endTime"&orderRequest.from_station_name=$fromStationName&orderRequest.to_station_name="$toStationName"&orderRequest.cancel_flag=1&orderRequest.id_mode=Y&passengerTickets="$seatType"%2C1%2C"$passengerName"%2C1%2C"$passengerId"%2C"$passengerMobile"%2CY&oldPassengers=&passenger_1_seat="$seatType"&passenger_1_ticket=1&passenger_1_name="$passengerName"&passenger_1_cardtype=1&passenger_1_cardno="$passengerId"&passenger_1_mobileno="$passengerMobile"&checkbox9=Y&randCode="$verifyCode"&orderRequest.reserve_flag=A"

    url="https://dynamic.12306.cn/otsweb/order/confirmPassengerAction.do?method=confirmPassengerInfoSingle"
    curl -k --connect-timeout 5 -H "$userAgent" --cookie "$cookie" --referer "$referer" -d "$postData" "$url" > order.html
    echo $(date +"%T") Recived response data

    cat ./order.html | grep "var message ="

    tokenString=$(cat ./order.html | grep TOKEN)

    for i in $(echo $tokenString | tr "\"" "\n"); do
        if [ ${#i} -eq 32 ]; then
            realToken=$i;
        fi;
    done

    echo $(date +"%T") Got new token $realToken
    
done
