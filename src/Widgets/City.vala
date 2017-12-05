/*
* Copyright (c) 2017 Carlos Suárez (https://github.com/bitseater)
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
* Authored by: Carlos Suárez <bitseater@gmail.com>
*/
namespace  Weather.Widgets {

    public class City : Gtk.Box {

        private Settings setting;
        private Gtk.TreeView cityview;

        struct Mycity {
            string country;
            int id;
            string name;
            double lat;
            double lon;
        }

        public City (Gtk.Window window, Weather.Widgets.Header header) {
            orientation = Gtk.Orientation.VERTICAL;
            spacing = 5;

            header.set_title ("");
            header.change_visible (false);

            setting = new Settings ("com.github.bitseater.weather");
            var search_line = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
            pack_start (search_line, false, false, 5);
            var uri1 = Constants.OWM_API_ADDR + "find?q=";
            var uri2 = "&type=like&APPID=" + setting.get_string ("apiid");

            var citylabel = new Gtk.Label (_("Search for new location:"));
            search_line.pack_start (citylabel, false, false, 5);
            var cityentry = new Gtk.Entry ();
            cityentry.max_length = 40;
            cityentry.primary_icon_name = "system-search-symbolic";
            cityentry.secondary_icon_name = "edit-clear-symbolic";
            search_line.pack_start (cityentry, true, true, 5);

            cityview = new Gtk.TreeView ();
            cityview.expand = true;
            var citylist = new Gtk.ListStore (5, typeof (string), typeof (int), typeof (string), typeof (double), typeof (double));
            cityview.model = citylist;
            cityview.insert_column_with_attributes (-1, _("Country"), new Gtk.CellRendererText (), "text", 0);
            cityview.insert_column_with_attributes (-1, _("OpenWM ID"), new Gtk.CellRendererText (), "text", 1);
            cityview.insert_column_with_attributes (-1, _("City"), new Gtk.CellRendererText (), "text", 2);
            var scroll = new Gtk.ScrolledWindow (null,null);
            scroll.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            scroll.add (cityview);

            cityentry.icon_press.connect ((pos, event) => {
                if (pos == Gtk.EntryIconPosition.SECONDARY) {
                    cityentry.set_text ("");
                    citylist.clear ();
                }
            });

            var overlay = new Gtk.Overlay ();
            pack_end (overlay, true, true, 0);
            var ticket = new Weather.Widgets.Ticket ("");
            overlay.add_overlay (scroll);
            overlay.add_overlay (ticket);

            setting.get_string ("country");
            setting.changed["country"].connect (() => {
                window.remove (window.get_child ());
                var current = new Weather.Widgets.Current (window, header);
                window.add (current);
                window.show_all ();
            });

            cityentry.changed.connect (() => {
                if (cityentry.get_text_length () < 3) {
                    citylist.clear ();
                    ticket.set_text (_("At least of 3 characters are required!"));
                    ticket.reveal_child = true;
                    ticket.showtime (1500);
                } else {
                    string uri = "";
                    citylist.clear ();
                    uri = uri1 + cityentry.get_text () + uri2;
                    var session = new Soup.Session ();
                    var message = new Soup.Message ("GET", uri);
                    session.send_message (message);
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) message.response_body.flatten ().data, -1);

                        var root = parser.get_root ().get_object ();
                        var city = root.get_array_member ("list");
                        if (root.get_int_member ("count") == 0) {
                            ticket.set_text (_("No data"));
                            ticket.reveal_child = true;
                            ticket.showtime (1500);
                        } else {
                            Gtk.TreeIter iter;
                            foreach (var geonode in city.get_elements ()) {
                                var geoname = geonode.get_object ();
                                citylist.append (out iter);
                                citylist.set (iter, 0, geoname.get_object_member ("sys").get_string_member ("country"),
                                                    1, geoname.get_int_member ("id"),
                                                    2, geoname.get_string_member ("name"),
                                                    3, geoname.get_object_member ("coord").get_double_member ("lat"),
                                                    4, geoname.get_object_member ("coord").get_double_member ("lon"));
                            }
                        }
                    } catch (Error e) {
                            stderr.printf (_("Found an error"));
                    }
                }
            });
            cityview.row_activated.connect (on_row_activated);
            cityview.get_selection().changed.connect (() => {
                Gtk.TreeModel model;
                Gtk.TreeIter iter;
                if (cityview.get_selection ().get_selected (out model, out iter)) {
                    Mycity city = def_selection (this.cityview.model, iter);
                    var mapview = new Weather.Utils.MapCity (city.lat, city.lon);
                    mapview.show_all ();
                }
            });
        }

        private static Mycity def_selection (Gtk.TreeModel model, Gtk.TreeIter iter) {
            var city = Mycity ();
            model.get (iter, 0, out city.country, 1, out city.id, 2, out city.name, 3, out city.lat, 4, out city.lon);
            return city;
        }

        private void on_row_activated (Gtk.TreeView cityview , Gtk.TreePath path, Gtk.TreeViewColumn column) {
            Gtk.TreeIter iter;
            if (cityview.model.get_iter (out iter, path)) {
                Mycity city = def_selection (cityview.model, iter);
                var setting = new Settings ("com.github.bitseater.weather");
                setting.set_string ("location", city.name);
                setting.set_string ("idplace", city.id.to_string());
                setting.set_string ("country", city.country);
            }
        }
    }
}
