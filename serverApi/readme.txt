
package require http
package require tls

::http::register https 443 ::tls::socket

set url https://127.0.0.1:8834/session
set body [http::formatQuery username admin password myPassword]
set login [http::geturl $url -query $body]
set authToken [http::data $login]

http::cleanup $token


The best solution would seem to be to not create a json object and then convert it to a dict, but instead create the dict directly, like this:

set data [list uuid $uuid settings [list name $name description $desc policy_id $pid text_targets $target launch ONETIME enabled false launch_now true]]
or like this, for shorter lines:

dict set data uuid $uuid
dict set data settings name $name
dict set data settings description $desc
dict set data settings policy_id $pid
dict set data settings text_targets $target
dict set data settings launch ONETIME
dict set data settings enabled false
dict set data settings launch_now true

ObjectTypes "OTYP_GROUNDER OTYP_GROUND_SWITCH OTYP_SHORTING_SWITCH"



 set au [ dict create auth "basic $user $pass" ]
   set res [rest::simple http://${server_host}/rsdu/scada/api/app/info  [list ]  {
          method get
          $au
          format json
        }
  ]





set server(apis) {
   method get
   auth basic
   format json
}



   
   rest::create_interface server
   server::basic_auth $user $pass
   set res  [  server::gets  ] 





    package require Tcl 8.5
    package require rest ?1.0.1?

    ::rest::simple url query ?config? ?body?
    ::rest::get url query ?config? ?body?
    ::rest::post url query ?config? ?body?
    ::rest::head url query ?config? ?body?
    ::rest::put url query ?config? ?body?
    ::rest::delete url query ?config? ?body?
    ::rest::save name file
    ::rest::describe name
    ::rest::parameters url ?args?
    ::rest::parse_opts static required optional string
    ::rest::substitute string ?var?
    ::rest::create_interface name
    describe
    uplevel token token
    upvar body body
    uplevel token token
    uplevel token token


---------------

    set appid APPID
    set search tcl
    set res [rest::get http://boss.yahooapis.com/ysearch/web/v1/$search [list appid $appid]]
    set res [rest::format_json $res]

    set res [rest::simple http://twitter.com/statuses/update.json  [list status $text]  {
          method post
          auth {basic user password}
          format json
        }
    ]


GET http://{{server_host}}/rsdu/scada/api/app/topology/graph 
Content-Type: application/json; charset=utf-8
Accept: application/json; charset=utf-8
Authorization: RSDU {{sessionid}}



