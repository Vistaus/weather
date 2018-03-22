/*
* Copyright (c) 2017-2018 Carlos Suárez (https://github.com/bitseater)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; If not, see <http://www.gnu.org/licenses/>.
*
* Authored by: Carlos Suárez <bitseater@gmail.com>
*/
namespace  Weather.Widgets {

    public class City : Gtk.ScrolledWindow {

        private Settings setting;
        private Weather.Utils.MapCity mapcity;
        private Gtk.ListBoxRow row;
        private Gtk.Box hbox;

        public City (Weather.MainWindow window, Weather.Widgets.Header header) {
            hscrollbar_policy = Gtk.PolicyType.NEVER;
            vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;

            header.change_visible (false);
            var entry = new Gtk.SearchEntry ();
            entry.placeholder_text = _("Search for new location:");
            entry.width_chars = 30;
            header.custom_title = entry;

            setting = new Settings ("com.github.bitseater.weather");
            var uri1 = Constants.OWM_API_ADDR + "weather?lat=";
            var uri2 = "&APPID=" + setting.get_string ("apiid");

            var box = new Gtk.ListBox ();
            box.selection_mode = Gtk.SelectionMode.NONE;
            entry.activate.connect (() => {
                box.forall ((row) => box.remove (row));
                if (entry.get_text_length () < 3) {
                    window.ticket.set_text (_("At least of 3 characters are required!"));
                    window.ticket.reveal_child = true;
                } else {
                    var busqueda = new Geocode.Forward.for_string (entry.get_text ());
                    try {
                        var cities = busqueda.search ();
                        int i = 0;
                        foreach (var city in cities) {
                            var tipo = city.place_type;
                            var town = city.town;
                            if (tipo == Geocode.PlaceType.TOWN && town != null) {
                                hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
                                hbox.halign = Gtk.Align.FILL;
                                hbox.set_border_width (10);
                                var state = city.state;
                                var country = city.country_code;
                                var lat = city.location.latitude;
                                var lon = city.location.longitude;
                                var icon = new Gtk.Button ();
                                icon.relief = Gtk.ReliefStyle.NONE;
                                icon.halign = Gtk.Align.START;
                                icon.valign = Gtk.Align.CENTER;
                                var minimap = new Weather.Utils.MiniMap (lat, lon, 50);
                                icon.image = minimap;
                                minimap.show_all ();
                                icon.button_press_event.connect (() => {
                                    mapcity = new Weather.Utils.MapCity (lat, lon, icon);
                                    mapcity.show_all ();
                                    return true;
                                });
                                icon.button_release_event.connect (() => {
                                    mapcity.hide ();
                                    return false;
                                });
                                var place = new Gtk.Label (town + ", " + state + " " + country);
                                place.halign = Gtk.Align.CENTER;
                                place.valign = Gtk.Align.CENTER;
                                var select = new Gtk.Button.with_label (_("Select"));
                                select.clicked.connect (() => {
                                    string uri = uri1 + lat.to_string () + "&lon=" + lon.to_string () + uri2;
                                    setting.set_string ("idplace", update_id (uri).to_string());
                                    if (town != null) {
                                        setting.set_string ("location", town);
                                    } else {
                                        setting.set_string ("location", "");
                                    }
                                    if (state != null) {
                                        setting.set_string ("state", state);
                                    } else {
                                        setting.set_string ("state", "");
                                    }
                                    if (country != null) {
                                        setting.set_string ("country", country);
                                    } else {
                                        setting.set_string ("country", "");
                                    }
                                    header.custom_title = null;
                                    header.title = town + ", " + state + " " + country;
                                    header.restart_switcher ();
                                    var current = new Weather.Widgets.Current (window, header);
                                    window.change_view (current);
                                    window.show_all ();

                                });
                                select.halign = Gtk.Align.END;
                                select.valign = Gtk.Align.CENTER;
                                hbox.pack_start (icon, false, true, 5);
                                hbox.pack_start (place, true, true, 5);
                                hbox.pack_end (select, true, true, 5);
                                hbox.show_all ();
                                row = new Gtk.ListBoxRow ();
                                row.add (hbox);
                                box.add (row);
                                hbox.show_all ();
                                row.show_all ();
                                box.show_all ();
                                i++;
                            }
                        }
                    } catch (Error error) {
                        window.ticket.set_text (_("No data"));
                        window.ticket.reveal_child = true;
                    }
                }
            });
            entry.backspace.connect (() => {
                box.forall ((row) => box.remove (row));
                if (entry.get_text_length () < 3) {
                    window.ticket.set_text (_("At least of 3 characters are required!"));
                    window.ticket.reveal_child = true;
                }
            });
            entry.icon_press.connect ((pos, event) => {
                    if (pos == Gtk.EntryIconPosition.SECONDARY) {
                        box.forall ((row) => box.remove (row));
                        window.ticket.set_text (_("At least of 3 characters are required!"));
                        window.ticket.reveal_child = true;
                    }
            });
            add (box);
        }

        private static int64 update_id (string uri) {
            var session = new Soup.Session ();
            var message = new Soup.Message ("GET", uri);
            session.send_message (message);
            int64 id = 0;
            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) message.response_body.flatten ().data, -1);
                var root = parser.get_root ().get_object ();
                id = root.get_int_member ("id");
            } catch (Error e) {
                debug (e.message);
            }
            return id;
        }
    }
}
