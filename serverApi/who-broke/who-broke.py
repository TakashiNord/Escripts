import argparse

import requests


def logon(url, username, password):
    """
    Logon into SCADA server
    :param url: Host:Port
    :param username:
    :param password:
    :return: [url, Session identifier] or None
    """
    try:
        r = requests.post(f'http://{url}/rsdu/session/logon',
                          json={"Login": username, "Password": password}, timeout=3)

        if r.status_code != 200:
            return None

        session = r.json()

    except requests.exceptions.RequestException:
        return None

    return [url, session.get('SessionId', session.get('sessionId'))]


def get_equipment_by_guid(session, guid):
    """
    Get object JSON by its GUID
    :param session:
    :param guid:
    :return: JSON or None
    """
    try:
        r = requests.get(f'http://{session[0]}/rsdu/scada/api/model/objstruct/objects/{guid}',
                         headers={'Authorization': 'RSDU ' + session[1]})

        if r.status_code == 200:
            return r.json()
        else:
            return None

    except requests.exceptions.RequestException:
        return None


def get_equipments_state(session):
    """
    Get objects state
    :param session:
    :return: [JSON] or None
    """
    try:
        r = requests.post(f'http://{session[0]}/rsdu/scada/api/app/topology/raw/network/state',
                          json={
                              "ObjectTypes": [
                                  "OTYP_GROUNDER",
                                  "OTYP_GROUND_SWITCH",
                                  "OTYP_SHORTING_SWITCH"
                              ]},
                          headers={'Authorization': 'RSDU ' + session[1]})

        if r.status_code == 200:
            return r.json()
        else:
            return None

    except requests.exceptions.RequestException:
        return None


def main(args):
    session = logon(args.url, args.username, args.password)
    if session is not None:
        equipments_state = get_equipments_state(session)

        for item in equipments_state:
            if item['State'] == 'Damaged':
                guid = item['ObjectId']
                find = True
                idx = 0
                while find:
                    equipment_json = get_equipment_by_guid(session, guid)
                    parent_uid = equipment_json.get('ParentUid')
                    equipment_type = equipment_json.get('Type')

                    if equipment_type is None:
                        break

                    equipment_type_alias = equipment_type.get('DefineAlias')

                    if parent_uid is None or equipment_type_alias == 'OTYP_SUBSTATION':
                        find = False

                    name = equipment_json.get('Name')
                    equipment_type_name = equipment_type.get('Name')

                    if idx == 0:
                        print(f"● {equipment_type_name}:{name} GUID:{guid}")
                    else:
                        print(f"{' ' * idx}↘︎ {equipment_type_name}:{name} GUID:{guid}")
                    idx += 1
                    guid = parent_uid
    else:
        print(f'Login error: {args.url}/{args.username}/{args.password}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('url', help='SCADA API Host:Port', type=str)
    parser.add_argument('username', help='Username', nargs='?', type=str, default='admin')
    parser.add_argument('password', help='Password', nargs='?', type=str, default='passme')
    main(parser.parse_args())
