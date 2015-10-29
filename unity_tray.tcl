# unity_tray.tcl --
#
#       Tkabber unity_tray Module.
#
# Requirements:
#       osd_cat:    Utility to put messages on-screen. (apt-get install
#                   xosd-bin in Debian)
#
# Author: Jan Hudec
# Modifications: Sergei Golovan <sgolovan@nes.ru>

package require msgcat


namespace eval ::unity_tray {
    ::msgcat::mcload [file join [file dirname [info script]] msgs]

    if {![::plugins::is_registered unity_tray]} {
        ::plugins::register unity_tray \
                            -namespace [namespace current] \
                            -source [info script] \
                            -description [::msgcat::mc "Whether the unity_tray plugin\
                                                        is loaded."] \
                            -loadcommand [namespace code load] \
                            -unloadcommand [namespace code unload]
        return
    }



    set options ""
    set delay 5
    set unity_trayfont ""
    set pipe ""
    array set statuses {}
}

proc ::unity_tray::load {} {
    #if {![info exists ::unity_tray] || $::unity_tray == ""} {
    #  debugmsg unity_tray "Failed to find unity_tray"
    #  return
    #}



    ::unity_tray::open_unity_tray_cat

    foreach event $::unity_tray {
        puts event
        switch -- $event {
            presence {
                hook::add client_presence_hook ::unity_tray::presence_notify 100
            }
            chat_message {
                hook::add draw_message_hook ::unity_tray::chat_message_notify 20
            }
            default {
                debugmsg unity_tray "Unsupported notify type $event"
            }
        }
    }
}

proc ::unity_tray::unload {} {
    if {![info exists ::unity_tray] || $::unity_tray == ""} {
      return
    }

    foreach event $::unity_tray {
        switch -- $event {
            presence {
                hook::remove client_presence_hook ::unity_tray::presence_notify 100
            }
            chat_message {
                hook::remove draw_message_hook ::unity_tray::chat_message_notify 20
            }
            default {
                debugmsg unity_tray "Unsupported notify type $event"
            }
        }
    }

    variable pipe
    unity_tray::try_write "q"
    close $pipe
    set pipe ""
}

proc ::unity_tray::open_unity_tray_cat {} {
    variable pipe
    variable options
    variable delay
    variable unity_trayfont
    if {$pipe != ""} {
        close $pipe
        set pipe ""
    }
    set command "|/home/kerrigan/.tkabber/plugins/unity_tray/unity_tray"

    #if {$unity_trayfont != ""} {
    #    append command " -f $unity_trayfont"
    #}
    debugmsg unity_tray $command
    set pipe [open $command w]
    fconfigure $pipe -buffering line
}

proc ::unity_tray::try_write {text} {
    variable pipe
    if {[catch {puts $pipe $text}]} {
        unity_tray::open_unity_tray_cat
        if {[catch {puts $pipe $text}]} {
            debugmsg unity_tray "Can't write to unity_tray"
        }
    }
}

proc ::unity_tray::presence_notify {xlib from type x args} {
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

    if {"$newstatus" != "$oldstatus"} {
        unity_tray::try_write "$newstatus"
    }

    set statuses($from) "$newstatus"
}

proc ::unity_tray::chat_message_notify {chatid from type body extras} {
    if {[chat::is_our_jid $chatid $from] || $type ne "chat"} {
        unity_tray::try_write "a"
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

    set nick [get_nick [chat::get_xlib $chatid] $from $type]
    unity_tray::try_write "p"
}

proc ::unity_tray::get_nick {xlib jid type} {
    if {[catch {chat::get_nick $xlib $jid $type} nick]} {
        return [chat::get_nick $jid $type]
    } else {
        return $nick
    }
}

# vim:ts=8:sw=4:sts=4:et
