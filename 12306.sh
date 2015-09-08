#!/bin/bash

####################
# Variables
####################
userAgent="User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:9.0.1) Gecko/20100101 Firefox/9.0.1"
username=""
password=""
trainDate=""
trainNo=""
trainLongNo=""
fromStationCode=""
fromStationName=""
toStationCode=""
toStationName=""
startTime=""
endTime=""
seatType="" # O 二等座   M 一等座   P 特等座   1 硬座   3 硬卧   4 软卧
passengerName=""
passengerId=""
passengerMobile=""
cookie=""
PROGNAME=${0##*/}
operation=""
verifyCode=""
orderVerifyCode=""
realToken=""


####################
# Functions
####################
function log(){
    currentTime=$(date +"%T")
    
    echo $currentTime $1
}

function urlencode() {
    echo -n "$1" | perl -MURI::Escape -ne 'print uri_escape($_)'
}

function urldecode() {
    echo -n "$1" | perl -MURI::Escape -ne 'print uri_unescape($_)'
}

function getCookies(){
    curl -x localhost:8888 -s -k --connect-timeout 5 -H "$userAgent" --referer "$referer" -D "head.txt" -G "https://dynamic.12306.cn/otsweb/" > /dev/empty
    echo $(cat ./head.txt | grep Set-Cookie | awk '{print $2}' | tr "\n" " ")
}

function downloadVerifyCodeImage(){
    curl -x localhost:8888 -s -k --connect-timeout 5 -H "$userAgent" --cookie "$cookie" --referer "$referer" "https://dynamic.12306.cn/otsweb/passCodeAction.do?rand=lrand" > code.jpg
}

function inputVerifyCode(){
    cmd /C "code.jpg"
    read -p "Verify code(press enter to get a new one): " code
    echo $code
}


function downloadOrderVerifyCodeImage(){
    curl -x localhost:8888 -s -k --connect-timeout 5 -H "$userAgent" --cookie "$cookie" --referer "$referer" "https://dynamic.12306.cn/otsweb/passCodeAction.do?rand=randp" > order-code.jpg
}

function inputOrderVerifyCode(){
    cmd /C "order-code.jpg"
    read -p "Order verify code(press enter to get a new one): " code
    echo $code
}

function getStationCodeByName(){
    echo $(cat station_names.txt | grep "$1" | tr "|" " " | awk '{print $2}')
}

function setLongTrainNoByName(){
    while [ 1 ]
    do
        content=$(curl -x localhost:8888 -s -k --connect-timeout 5 -d "date=$3&fromstation=$1&tostation=$2&starttime=00%3A00--24%3A00" "https://dynamic.12306.cn/otsweb/order/querySingleAction.do?method=queryststrainall")
    
        count=$(echo $content | grep -c "succde_fault.jpg")

        if [ $count -eq 0 ]
        then
            break;
        else
            log "Error in getting long train number"
        fi
    done

    
    trainLongNo=$(echo $content | tr "}" "\n" | grep \"$4\" | tr "\"" " " | awk '{print $12}')

    if [ -z $trainLongNo ]
    then
        trainLongNo=$(echo $content | tr "}" "\n" | grep \"$4\/ | tr "\"" " " | awk '{print $12}')
    fi

    if [ -z $trainLongNo ]
    then
        trainLongNo=$(echo $content | tr "}" "\n" | grep \/$4\" | tr "\"" " " | awk '{print $12}')
    fi
}

function showUsage(){
    echo "Help to book a train ticket on 12306.cn
You should log in 12306.cn and pay after ticket has been booked.

Usage: $PROGNAME method [options]

Method:
 login              Login only, must with -u -p -c -v
 order              Order only, must with -c -v -d -r -f -t -s -n -i -m
 login-and-order    Login and order, must with -u -p -d -r -f -t -s -n -i -m

Options:
 -u     Username
 -p     Password
 -d     Ticket date
 -r     Train number e.g., K525
 -R     Long train number e.g., 510000K52502
 -f     From station name e.g., 上海虹桥
 -t     Destination station name e.g., 北京西
 -s     Seat type: O - Second class seat    M - First class seat    P - Special class seat    9 - Bussiness class seat    1 - Hard seat    3 - Hard sleeper    4 - Soft sleeper
 -n     Passenger name
 -i     Passenger ID number
 -m     Passenger mobile number
 -c     Cookies
 -v     Verify code
 -h     Show this help"
}

function login(){
    referer="https://dynamic.12306.cn/otsweb/loginAction.do?method=init"

    postData="loginUser.user_name="$username"&org.apache.struts.taglib.html.TOKEN=2f91a78f9ba2afe110e7271c4e68b42f&nameErrorFocus=&user.password="$password"&passwordErrorFocus=&randCode="$verifyCode"&randErrorFocus="

    url="https://dynamic.12306.cn/otsweb/loginAction.do?method=login"

    while [ -z $verifyCode ];
    do
        downloadVerifyCodeImage
        verifyCode=$(inputVerifyCode)
    done

    while [ 1 ];
    do
        curl -x localhost:8888 -s -k --connect-timeout 5 -H "$userAgent" --cookie "$cookie" --referer "$referer" -d "$postData" "$url" > login.html

        verifyCodeCount=$(cat ./login.html | grep -c "请输入正确的验证码")

        isLoggedIn=$(cat ./login.html | grep -c "您最后一次登录时间为")

        cat ./login.html | grep "var message =" | awk '{print $4}'

        if [ $verifyCodeCount -eq 1 ]; then
            log "Verify code error"
            break
        else
            if [ $isLoggedIn -eq 1 ]; then
                log "Logged in"
                break
            else
                log "Kcuf 12306.cn"
                sleep 1
            fi
        fi
    done
}

function order(){
    referer="https://dynamic.12306.cn/otsweb/order/confirmPassengerAction.do?method=init"

    while [ 1 ]
    do
        orderVerifyCode=""
        while [ -z $orderVerifyCode ];
        do
            downloadOrderVerifyCodeImage
            orderVerifyCode=$(inputOrderVerifyCode)
        done
        log "begin order"
        postData="org.apache.struts.taglib.html.TOKEN="$realToken"&textfield=%E4%B8%AD%E6%96%87%E6%88%96%E6%8B%BC%E9%9F%B3%E9%A6%96%E5%AD%97%E6%AF%8D&checkbox2=2&orderRequest.train_date="$trainDate"&orderRequest.train_no="$trainLongNo"&orderRequest.station_train_code="$trainNo"&orderRequest.from_station_telecode="$fromStationCode"&orderRequest.to_station_telecode="$toStationCode"&orderRequest.seat_type_code=&orderRequest.ticket_type_order_num=&orderRequest.bed_level_order_num=000000000000000000000000000000&orderRequest.start_time="$startTime"&orderRequest.end_time="$endTime"&orderRequest.from_station_name=$fromStationName&orderRequest.to_station_name="$toStationName"&orderRequest.cancel_flag=1&orderRequest.id_mode=Y&passengerTickets="$seatType"%2C1%2C"$passengerName"%2C1%2C"$passengerId"%2C"$passengerMobile"%2CY&oldPassengers=&passenger_1_seat="$seatType"&passenger_1_ticket=1&passenger_1_name="$passengerName"&passenger_1_cardtype=1&passenger_1_cardno="$passengerId"&passenger_1_mobileno="$passengerMobile"&checkbox9=Y&randCode="$orderVerifyCode"&orderRequest.reserve_flag=A"

        url="https://dynamic.12306.cn/otsweb/order/confirmPassengerAction.do?method=confirmPassengerInfoSingle"
        curl -x localhost:8888 -s -k --connect-timeout 5 -H "$userAgent" --cookie "$cookie" --referer "$referer" -d "$postData" "$url" > order.html

        log "Finished order request"

        realToken=""
        
        message=$(cat ./order.html | grep "var message =")

        echo $message

        isOrderSucceed=$(echo $message | grep -c "目前您还有未处理的")

        if [ $isOrderSucceed -eq 1 ]
        then
            log "Order Success!!!"
            exit
        fi

        cat ./order.html | grep "succde_fault.jpg" | tr ">" " " | tr "<" " " | awk '{print $5}'

        tokenString=$(cat ./order.html | grep TOKEN)

        for i in $(echo $tokenString | tr "\"" "\n"); do
            if [ ${#i} -eq 32 ]; then
                realToken=$i;
            fi;
        done

        if [ -z $realToken ]
        then
            log "Token is empty, try to get one from other page"
            setTokenFromOtherPage
        fi

        log "Got new token $realToken"

        sleep 3
    done
}

function setTokenFromOtherPage(){
    while [ -z $realToken ]
    do
        log "Begin to get token from other page"
        curl -x localhost:8888 -G --connect-timeout 5 -k -H "$userAgent" --referer "https://dynamic.12306.cn/otsweb/" --cookie "$cookie" "https://dynamic.12306.cn/otsweb/order/querySingleAction.do?method=init"
        log "End request, try to parse"

        tokenString=$(cat ./confirm.html | grep TOKEN)

        for i in $(echo $tokenString | tr "\"" "\n"); do
            if [ ${#i} -eq 32 ]; then
                realToken=$i;
            fi;
        done

        if [ -z $realToken ]
        then
            log "Token is still empty, re-try"
        else
            break
        fi
    done
}

function main(){
    if [ -z "$cookie" ]
    then
        cookie=$(getCookies)
    fi

    if [ $operation == "login" ]
    then
        login
    elif [ $operation == "order" ]
    then
        order
    elif [ $operation == "login-and-order" ]
    then
        login
        order
    fi
}

function checkParameters(){
    if [ $operation == 'login' -o $operation == 'order' -o $operation == 'login-and-order' ]
    then
        echo 'OK'
    else
        showUsage
        exit
    fi
}

function prepareParameters(){
    if [ -z $trainLongNo ]
    then
        setLongTrainNoByName $fromStationCode $toStationCode $trainDate $trainNo
    fi


    startTime=$(urlencode "06:50")
    endTime=$(urlencode "09:23")
}

function debug(){
    echo "
User-Agent:         $userAgent
Username:           $(urldecode $username)
Password:           $password
Train Date:         $trainDate
Train Number:       $trainNo
Train Number(Long): $trainLongNo
From Station Code:  $fromStationCode
From Station Name:  $(urldecode $fromStationName)
To Station Code:    $toStationCode
To Station Name:    $(urldecode $toStationName)
Train Start Time:   $startTime
Train Arrive Time:  $endTime
Seat Type:          $seatType
Passenger Name:     $(urldecode $passengerName)
Passenger ID:       $passengerId
Passenger Moble:    $passengerMobile
Cookie:             $cookie
Program Name:       $PROGNAME
Operation:          $operation
Verify Code:        $verifyCode"
}


####################
# Main
####################
operation=$1
shift

while getopts "u:p:d:r:R:f:t:s:n:i:m:c:v:h" optname
    do
        case "$optname" in
            "u")
                username=$(urlencode $OPTARG)
                ;;
            "p")
                password=$OPTARG
                ;;
            "d")
                trainDate=$OPTARG
                ;;
            "r")
                trainNo=$OPTARG
                ;;
            "R")
                trainLongNo=$OPTARG
                ;;
            "f")
                fromStationName=$OPTARG
                fromStationCode=$(getStationCodeByName $fromStationName)
                fromStationName=$(urlencode $fromStationName)
                ;;
            "t")
                toStationName=$OPTARG
                toStationCode=$(getStationCodeByName $toStationName)
                toStationName=$(urlencode $toStationName)
                ;;
            "s")
                seatType=$OPTARG
                ;;
            "n")
                passengerName=$(urlencode $OPTARG)
                ;;
            "i")
                passengerId=$OPTARG
                ;;
            "m")
               passengerMobile=$OPTARG
                ;;
            "c")
                cookie=$OPTARG
                ;;
            "v")
                verifyCode=$OPTARG
                ;;
            "h")
               showUsage
               exit
                ;;
            "?")
                echo "Unknown option $OPTARG"
                showUsage
                exit
                ;;
            ":")
                echo "No argument value for option $OPTARG"
                showUsage
                exit
                ;;
            *)
                # Should not occur
                echo "Unknown error while processing options"
                showUsage
                exit
                ;;
        esac
done

checkParameters
prepareParameters
debug
main
