# unitytray.tcl --
#
#       Tkabber unitytray Module.
#
# Requirements:
#       unity_tray:    Utility to put messages on-screen. (apt-get install
#                   xosd-bin in Debian)
#
# Author: Jan Hudec
# Modifications: Sara Kerrigan <xybermind@gmail.com>

package require msgcat


#lappend ::auto_path /usr/share/ramdebugger/addons
#package require commR
#comm::register application_name 1

namespace eval ::unitytray {
    ::msgcat::mcload [file join [file dirname [info script]] msgs]

    if {![::plugins::is_registered unitytray]} {
        ::plugins::register unitytray \
                            -namespace [namespace current] \
                            -source [info script] \
                            -description [::msgcat::mc "Whether the unitytray plugin\
                                                        is loaded."] \
                            -loadcommand [namespace code load] \
                            -unloadcommand [namespace code unload]
        return
    }


    variable window_active

    set options ""
    set delay 5
    set unitytrayfont ""
    set pipe ""
    set window_active true
    array set statuses {}
}

proc ::unitytray::load {} {
    if {![info exists ::unitytray] || $::unitytray == ""} {
      return
    }



    ::unitytray::open_unitytray_cat


    hook::add got_focus_hook ::unitytray::chat_opened 20
    hook::add lost_focus_hook ::unitytray::chat_minimized 20

    foreach event $::unitytray {
        switch -- $event {
            presence {
                hook::add client_presence_hook ::unitytray::presence_notify 100
            }
            chat_message {
                hook::add draw_message_hook ::unitytray::chat_message_notify 20
            }
            default {
                debugmsg unitytray "Unsupported notify type $event"
            }
        }
    }
}

proc ::unitytray::unload {} {
    if {![info exists ::unitytray] || $::unitytray == ""} {
      return
    }

    foreach event $::unitytray {
        switch -- $event {
            presence {
                hook::remove client_presence_hook ::unitytray::presence_notify 100
            }
            chat_message {
                hook::remove draw_message_hook ::unitytray::chat_message_notify 20
            }
            default {
                debugmsg unitytray "Unsupported notify type $event"
            }
        }
    }


    hook::remove got_focus_hook ::unitytray::chat_opened 20
    hook::remove lost_focus_hook ::unitytray::chat_minimized 20

    variable pipe
    unitytray::try_write "q"
    close $pipe
    set pipe ""
}

proc ::unitytray::open_unitytray_cat {} {
    variable pipe
    variable options
    variable delay
    variable unitytrayfont
    if {$pipe != ""} {
        close $pipe
        set pipe ""
    }
    set command "|/home/kerrigan/.tkabber/plugins/unitytray/unity_tray"

    #if {$unitytrayfont != ""} {
    #    append command " -f $unitytrayfont"
    #}
    debugmsg unitytray $command
    set pipe [open $command w]
    fconfigure $pipe -buffering line
}

proc ::unitytray::try_write {text} {
    variable pipe
    if {[catch {puts $pipe $text}]} {
        unitytray::open_unitytray_cat
        if {[catch {puts $pipe $text}]} {
            debugmsg unitytray "Can't write to unitytray"
        }
    }
}



#When window opened
proc ::unitytray::chat_opened {$path} {
    unitytray::try_write "c"

    variable window_active
    set window_active true
}

#When window minimized or lost focus
proc ::unitytray::chat_minimized {$path} {
    variable window_active
    set window_active false
}

proc ::unitytray::presence_notify {xlib from type x args} {
    variable statuses

    if {[catch  { set nick [get_nick $xlib $from chat] }]} {
        set nick "$from"
    }

    if {"$nick" != "$from"} {
        set thefrom "$nick ($from)"
    } else {
        set thefrom "$from"
    }
    if {"$type" == ""} {
        set type "available"
    }

    set status ""
    set show ""
    foreach {attr val} $args {
        switch -- $attr {
            -status {
                set status $val
            }
            -show {
                set show $val
            }
        }
    }

    if {"$status" != ""} {
        set status " ($status)"
    }
    if {"$show" != ""} {
        set type "$type/$show"
    }

    set newstatus "$thefrom: $type$status"

    if {[catch { set oldstatus $statuses($from) } ]} {
        set oldstatus "$newstatus"
    }

    #if {"$newstatus" != "$oldstatus"} {
    #    unitytray::try_write "$newstatus"
    #}

    set statuses($from) "$newstatus"
}

proc ::unitytray::chat_message_notify {chatid from type body extras} {
    variable window_active
    if {$window_active eq true} {
      return
    }

    if {[chat::is_our_jid $chatid $from]} {
        return
    }





    foreach xelem $extras {
        ::xmpp::xml::split $xelem tag xmlns attrs cdata subels

        # Don't notify if this 'empty' tag is present. It indicates
        # messages history in chat window.
        if {[string equal $tag ""] && [string equal $xmlns tkabber:x:nolog]} {
            return
        }
    }


    if {$type eq "chat"} {
        unitytray::try_write "p"
        return
    }



    set nick [get_nick [chat::get_xlib $chatid] $from $type]

    set our_nick [get_our_groupchat_nick $chatid]
    if {$type eq "groupchat"} {
        # if mentioned - show private
        if {[check_message $our_nick $body] eq 1} {
            unitytray::try_write "p"
        } else {
            unitytray::try_write "a"
        }
        return;
    }




}

proc ::unitytray::get_nick {xlib jid type} {
    if {[catch {chat::get_nick $xlib $jid $type} nick]} {
        return [chat::get_nick $jid $type]
    } else {
        return $nick
    }
}

# vim:ts=8:sw=4:sts=4:et
