#include <stdbool.h>
#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <libappindicator/app-indicator.h>


#define PLUGIN_PATH "/home/kerrigan/.tkabber/plugins/unitytray/"

static void activate_action (GtkAction *action);

static GtkActionEntry entries[] = {
  { "FileMenu", NULL, "_File" },
  { "New",      "document-new", "_New", "<control>N",
    "Create a new file", G_CALLBACK (activate_action) },
  { "Open",     "document-open", "_Open", "<control>O",
    "Open a file", G_CALLBACK (activate_action) },
  { "Save",     "document-save", "_Save", "<control>S",
    "Save file", G_CALLBACK (activate_action) },
  { "Quit",     "application-exit", "_Quit", "<control>Q",
    "Exit the application", G_CALLBACK (gtk_main_quit) },
};
static guint n_entries = G_N_ELEMENTS (entries);

static const gchar *ui_info =
"<ui>"
"  <popup name='IndicatorPopup'>"
"    <menuitem action='New' />"
"    <menuitem action='Open' />"
"    <menuitem action='Save' />"
"    <menuitem action='Quit' />"
"  </popup>"
"</ui>";

static AppIndicator *indicator;

static void
activate_action (GtkAction *action)
{
        const gchar *name = gtk_action_get_name (action);
        GtkWidget *dialog;

        dialog = gtk_message_dialog_new (NULL,
                                         GTK_DIALOG_DESTROY_WITH_PARENT,
                                         GTK_MESSAGE_INFO,
                                         GTK_BUTTONS_CLOSE,
                                         "You activated action: \"%s\"",
                                         name);

        g_signal_connect (dialog, "response",
                          G_CALLBACK (gtk_widget_destroy), NULL);

        gtk_widget_show (dialog);

        //app_indicator_set_attention_icon
        app_indicator_set_icon (indicator, "/home/kerrigan/src/tkabber/tkabber-svn/emoticons/default/beer.gif");
}


gpointer mainloop(gpointer data){
      gtk_main();
}

int main (int argc, char **argv)
{
  GtkWidget *window;
  GtkWidget *menubar;
  GtkWidget *table;
  GtkWidget *sw;
  GtkWidget *contents;
  GtkWidget *statusbar;
  GtkWidget *indicator_menu;
  GtkActionGroup *action_group;
  GtkUIManager *uim;

  GError *error = NULL;

  gtk_init (&argc, &argv);

  /* main window */


  window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title (GTK_WINDOW (window), "Indicator Demo");
  gtk_window_set_icon_name (GTK_WINDOW (window), "indicator-messages-new");
  g_signal_connect (G_OBJECT (window),
                    "destroy",
                    G_CALLBACK (gtk_main_quit),
                    NULL);

  // Menus


  action_group = gtk_action_group_new ("AppActions");
  /*
  gtk_action_group_add_actions (action_group,
                                entries, n_entries,
                                window);
                                */


  uim = gtk_ui_manager_new ();
  g_object_set_data_full (G_OBJECT (window),
                          "ui-manager", uim,
                          g_object_unref);
  //gtk_ui_manager_insert_action_group (uim, action_group, 0);


  gtk_window_add_accel_group (GTK_WINDOW (window),
                              gtk_ui_manager_get_accel_group (uim));


  if (!gtk_ui_manager_add_ui_from_string (uim, ui_info, -1, &error))
    {
      g_message ("Failed to build menus: %s\n", error->message);
      g_error_free (error);
      error = NULL;
    }
  // Show the window
  //gtk_widget_show_all (window);


  const char* home = g_get_home_dir();
  const char* available_icon = g_build_filename(home, ".tkabber/plugins/unitytray/icons/available.png", NULL);
  const char* messages_icon = g_build_filename(home, ".tkabber/plugins/unitytray/icons/message.png", NULL);
  const char* private_icon = g_build_filename(home, ".tkabber/plugins/unitytray/icons/message-personal.png", NULL);


  /* Indicator */
  indicator = app_indicator_new ("example-simple-client",
                                 available_icon,
                                 APP_INDICATOR_CATEGORY_APPLICATION_STATUS);

  indicator_menu = gtk_ui_manager_get_widget (uim, "/ui/IndicatorPopup");

  app_indicator_set_status (indicator, APP_INDICATOR_STATUS_ACTIVE);

  app_indicator_set_menu (indicator, GTK_MENU (indicator_menu));


  g_thread_new("gtk-loop", mainloop, NULL);

  //setvbuf(stdin, NULL, _IONBF, 0);
  char* base_path = g_get_current_dir();

  printf("%s\n", base_path);

  static bool got_private = false;

  printf("%s\n", argv[0]);



  char c;
  do {
      c = getchar();
      switch (c) {
          case 'a'/* value */:
            if(!got_private){
                app_indicator_set_icon (indicator, messages_icon);
            }
            break;
          case 'p':
            app_indicator_set_icon (indicator, private_icon);
            got_private = true;
            break;
          case 'c':
            app_indicator_set_icon(indicator, available_icon);
            got_private = false;
            break;
      }
  } while (c != 'q' || !c);

  return 0;
}

// gcc unity_tray.c `pkg-config gtk+-2.0 appindicator-0.1 --cflags --libs`  -o unitytray
