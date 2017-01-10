/**
 * Copyright 2013 Albert Vaca <albertvaka@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License or (at your option) version 3 or any later version
 * accepted by the membership of KDE e.V. (or its successor approved
 * by the membership of KDE e.V.), which shall act as a proxy
 * defined in Section 14 of version 3 of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.1
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kdeconnect 1.0
import QtQuick.Controls.Styles 1.4

PlasmaComponents.ListItem
{
    id: root
    readonly property QtObject device: DeviceDbusInterfaceFactory.create(model.deviceId)

    RemoteKeyboard {
        id: remoteKeyboard
        device: root.device
        onKeyPressReceived: {
            if (specialKey == 12)  // Return -> clear
                remoteKeyboardInput.text = "";
            else {
                var sanitized = "";
                for (var i = 0; i < key.length; i++) {
                    if (key.charCodeAt(i) > 31)
                        sanitized += key.charAt(i);
                }
                if (sanitized.length > 0 && !ctrl && !alt)
                    remoteKeyboardInput.text += sanitized;
            }
        }
    }

    Column {
        width: parent.width
        
        RowLayout
        {
            Item {
                //spacer to make the label centre aligned in a row yet still elide and everything
                implicitWidth: ring.width + browse.width + parent.spacing
            }

            PlasmaComponents.Label {
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: display
                Layout.fillWidth: true
            }

            //Find my phone
            PlasmaComponents.Button
            {
                FindMyPhone {
                    id: findmyphone
                    device: root.device
                }

                id: ring
                iconSource: "irc-voice"
                visible: findmyphone.available
                tooltip: i18n("Ring my phone")

                onClicked: {
                    findmyphone.ring()
                }
            }

            //SFTP
            PlasmaComponents.Button
            {
                Sftp {
                    id: sftp
                    device: root.device
                }

                id: browse
                iconSource: "document-open-folder"
                visible: sftp.available
                tooltip: i18n("Browse this device")

                onClicked: {
                    sftp.browse()
                }
            }

            height: browse.height
            width: parent.width
        }

        //RemoteKeyboard
        PlasmaComponents.ListItem {
            sectionDelegate: true
            visible: remoteKeyboard.available
            width: parent.width

            Row {
                width: parent.width
                spacing: 5

                PlasmaComponents.Label {
                    id: remoteKeyboardLabel
                    //font.bold: true
                    text: i18n("Remote Keyboard")
                }

                PlasmaComponents.TextField {
                    id: remoteKeyboardInput
                    textColor: "black"
                    height: parent.height
                    width: parent.width - 5 - remoteKeyboardLabel.width
                    verticalAlignment: TextInput.AlignVCenter
                    style: TextFieldStyle {
                        textColor: "black"
                        background: Rectangle {
                            radius: 2
                            border.color: "gray"
                            border.width: 1
                            color: "white"
                        }
                    }

                    Keys.onPressed: {
                        if (remoteKeyboard.available)
                            remoteKeyboard.sendEvent(event);
                        event.accepted = true;
                    }
                }
            }
        }

        //Battery
        PlasmaComponents.ListItem {

            Battery {
                id: battery
                device: root.device
            }

            sectionDelegate: true
            visible: battery.available
            PlasmaComponents.Label {
                //font.bold: true
                text: i18n("Battery")
            }
            PlasmaComponents.Label {
                text: battery.displayString
                anchors.right: parent.right
            }
        }

        //Notifications
        PlasmaComponents.ListItem {
            visible: notificationsModel.count>0
            enabled: true
            sectionDelegate: true
            PlasmaComponents.Label {
                //font.bold: true
                text: i18n("Notifications")
            }
            PlasmaComponents.ToolButton {
                enabled: true
                visible: notificationsModel.isAnyDimissable;
                anchors.right: parent.right
                iconSource: "window-close"
                onClicked: notificationsModel.dismissAll();
            }
        }
        Repeater {
            id: notificationsView
            model: NotificationsModel {
                id: notificationsModel
                deviceId: root.device.id()
            }
            delegate: PlasmaComponents.ListItem {
                id: listitem
                enabled: true
                onClicked: checked = !checked

                PlasmaComponents.Label {
                    text: appName + ": " + display
                    anchors.right: dismissButton.left
                    anchors.left: parent.left
                    elide: listitem.checked ? Text.ElideNone : Text.ElideRight
                    maximumLineCount: listitem.checked ? 0 : 1
                    wrapMode: Text.WordWrap
                }
                PlasmaComponents.ToolButton {
                    id: dismissButton
                    visible: notificationsModel.isAnyDimissable;
                    enabled: dismissable
                    anchors.right: parent.right
                    iconSource: "window-close"
                    onClicked: dbusInterface.dismiss();
                }
            }
        }

        //NOTE: More information could be displayed here

    }
}
