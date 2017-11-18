/*
* Copyright (c) 2017 bitseater ()
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
* Authored by: bitseater <bitseater@gmail.com>
*/
namespace  Weather.Widgets {

    public class Preferences : Gtk.Dialog {

        public Preferences (Gtk.Window window, Weather.Widgets.Header header) {
            this.resizable = false;
            this.deletable = false;
            this.transient_for = window;
            this.modal = true;

            var setting = new Settings ("com.github.bitseater.weather");

            var tit_pref = new Gtk.Label (_("Preferences"));
            tit_pref.get_style_context ().add_class ("h4");
            tit_pref.halign = Gtk.Align.START;
            var theme_lab = new Gtk.Label (_("Dark theme:"));
            theme_lab.halign = Gtk.Align.END;
            var theme = new Gtk.Switch ();
            theme.halign = Gtk.Align.START;
            if (setting.get_boolean ("dark")) {
                theme.active = true;
            } else {
                theme.active = false;
            }
            theme.notify["active"].connect (() => {
               if (theme.get_active ()) {
                   Gtk.Settings.get_default().set("gtk-application-prefer-dark-theme", true);
                   setting.set_boolean ("dark", true);
               } else {
                   Gtk.Settings.get_default().set("gtk-application-prefer-dark-theme", false);
                   setting.set_boolean ("dark", false);
               }
            });

            var unit_lab = new Gtk.Label (_("Units:"));
            unit_lab.halign = Gtk.Align.END;
            var unit_box = new Gtk.ComboBoxText ();
            unit_box.append_text (_("Metric System"));
            unit_box.append_text (_("Imperial System"));
            if (setting.get_string ("units") != "metric") {
                unit_box.active = 1;
            } else {
                unit_box.active = 0;
            }

            unit_box.changed.connect (() => {
                if (unit_box.active == 0) {
                    setting.set_string ("units", "metric");
                } else {
                    setting.set_string ("units", "imperial");
                }
            });

            var layout = new Gtk.Grid ();
            layout.column_spacing = 10;
            layout.row_spacing = 10;
            layout.margin = 15;

            layout.attach (tit_pref, 0, 0, 2, 1);
            layout.attach (theme_lab, 2, 1, 1, 1);
            layout.attach (theme, 3, 1, 1, 1);
            layout.attach (unit_lab, 2, 4, 1, 1);
            layout.attach (unit_box, 3, 4, 2, 1);

            Gtk.Box content = this.get_content_area () as Gtk.Box;
            content.border_width = 15;
            content.add (layout);

            this.add_button (_("Close"), Gtk.ResponseType.CANCEL);
            this.response.connect (() => {
                this.destroy ();
                window.remove (window.get_child ());
                if (setting.get_string ("apiid") == "") {
                    var apikey = new Weather.Widgets.Apikey (window, header);
                    window.add (apikey);
                } else if (setting.get_string ("idplace") == "") {
                    var city = new Weather.Widgets.City (window, header);
                    window.add (city);
                } else {
                    var current = new Weather.Widgets.Current (window, header);
                    window.add (current);
                }
                window.show_all ();
            });

            this.show_all ();
        }
    }
}