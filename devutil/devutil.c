//============================================================
//
//  devutil.c
//  Device installation helper
//  by Calamity - 03/2015
//
//============================================================

#include <windows.h>
#include <stdio.h>
#include <newdev.h>
#include <cfgmgr32.h>

int driver_install(int argc, char *argv[]);
int driver_uninstall(int argc, char *argv[]);
BOOL scan_for_hardware_changes();
int device_enable(int argc, char *argv[]);
int device_disable(int argc, char *argv[]);
int device_reset(int argc, char *argv[]);
int device_set_status(const char *hardware_id, int b_status);
void show_help(void);

#define WM_NEED_RESTART  WM_USER + 4000

//============================================================
//  show_help
//============================================================

void show_help(void)
{
	printf("\ndevutil 1.0 - (c) 2015 Calamity.\n\n");
	printf("usage:\n");
	printf("      devutil install   inf_file  pci_id  window_handle\n");
	printf("      devutil uninstall device_info_set_handle device_index\n");
	printf("      devutil scan\n");
	printf("      devutil enable pci_id\n");
	printf("      devutil disable pci_id\n");	
	printf("      devutil reset pci_id\n");
}

//============================================================
//  main
//============================================================

int main(int argc, char *argv[])
{
	if (argc < 2) goto exit;

	if (!strcmp(argv[1], "install"))
	{
		return driver_install(argc, &argv[0]);
	}
	else if (!strcmp(argv[1], "uninstall"))
	{
		return driver_uninstall(argc, &argv[0]);
	}
	else if (!strcmp(argv[1], "scan"))
	{
		return scan_for_hardware_changes();
	}
	else if (!strcmp(argv[1], "enable"))
	{
		return device_enable(argc, &argv[0]);
	}
	else if (!strcmp(argv[1], "disable"))
	{
		return device_disable(argc, &argv[0]);
	}
	else if (!strcmp(argv[1], "reset"))
	{
		return device_reset(argc, &argv[0]);
	}

exit:
	show_help();
	return ERROR_INVALID_PARAMETER;
}

//============================================================
//  driver_install
//============================================================

int driver_install(int argc, char *argv[])
{
	BOOL need_restart = false;

	if (argc < 5)
	{
		show_help();
		return ERROR_INVALID_PARAMETER;
	}

	HWND hwndParent;
	sscanf(argv[4], "%ul", &hwndParent);

	if (!UpdateDriverForPlugAndPlayDevices(hwndParent, argv[3], argv[2], INSTALLFLAG_FORCE, &need_restart))
		return GetLastError();

	if (need_restart)
		SendMessage(hwndParent, WM_NEED_RESTART, 0, 0);

	return ERROR_SUCCESS;
}

//============================================================
//  driver_uninstall
//============================================================

int driver_uninstall(int argc, char *argv[])
{
	if (argc < 4)
	{
		show_help();
		return ERROR_INVALID_PARAMETER;
	}

	int index;
	sscanf(argv[2], "%d", &index);

	HWND hwndParent;
	sscanf(argv[3], "%ul", &hwndParent);

	HDEVINFO device_info_set;
	device_info_set = SetupDiGetClassDevs(NULL, "PCI", NULL, DIGCF_ALLCLASSES | DIGCF_PRESENT);
	if (device_info_set == INVALID_HANDLE_VALUE)
		return -1;

	SP_DEVINFO_DATA device_info_data;
	device_info_data.cbSize = sizeof(SP_DEVINFO_DATA);

	if (!SetupDiEnumDeviceInfo(device_info_set, index, &device_info_data))
		return GetLastError();

	if (!SetupDiCallClassInstaller(DIF_REMOVE, device_info_set, &device_info_data))
		return GetLastError();

	SP_DEVINSTALL_PARAMS device_install_params;
	device_install_params.cbSize = sizeof(SP_DEVINSTALL_PARAMS);

	if (!SetupDiGetDeviceInstallParams(device_info_set, &device_info_data, &device_install_params))
		return GetLastError();

	if ((device_install_params.Flags & DI_NEEDREBOOT) || (device_install_params.Flags & DI_NEEDRESTART))
		SendMessage(hwndParent, WM_NEED_RESTART, 0, 0);

	return ERROR_SUCCESS;
}

//============================================================
//  scan_for_hardware_changes
//============================================================

BOOL scan_for_hardware_changes()
{
    DEVINST     devInst;
    CONFIGRET   status;

    // Get root devnode
    status = CM_Locate_DevNode(&devInst, NULL, CM_LOCATE_DEVNODE_NORMAL);

    if (status != CR_SUCCESS)
    {
        printf("CM_Locate_DevNode failed: %x\n", status);
        return FALSE;
    }

    status = CM_Reenumerate_DevNode(devInst, 0);

    if (status != CR_SUCCESS)
    {
        printf("CM_Reenumerate_DevNode failed: %x\n", status);
        return FALSE;
    }

    return TRUE;
}

//============================================================
//  device_enable
//============================================================

int device_enable(int argc, char *argv[])
{
	if (argc != 3)
	{
		show_help();
		return ERROR_INVALID_PARAMETER;
	}

	if (!device_set_status(argv[2], DICS_ENABLE))
		return GetLastError();

	return ERROR_SUCCESS;
}

//============================================================
//  device_disable
//============================================================

int device_disable(int argc, char *argv[])
{
	if (argc != 3)
	{
		show_help();
		return ERROR_INVALID_PARAMETER;
	}

	if (!device_set_status(argv[2], DICS_DISABLE))
		return GetLastError();

	return ERROR_SUCCESS;
}

//============================================================
//  device_reset
//============================================================

int device_reset(int argc, char *argv[])
{
	if (argc != 3)
	{
		show_help();
		return ERROR_INVALID_PARAMETER;
	}

	if (!device_set_status(argv[2], DICS_PROPCHANGE))
		return GetLastError();

	return ERROR_SUCCESS;
}

//============================================================
//  device_set_status
//============================================================

int device_set_status(const char *hardware_id, int state_change)
{
	int i, found;
	HDEVINFO hDI;
	SP_DEVINFO_DATA spDID;

	hDI = SetupDiGetClassDevs(NULL, "PCI", NULL, DIGCF_ALLCLASSES | DIGCF_PRESENT);
	if (hDI == INVALID_HANDLE_VALUE) return FALSE;

	spDID.cbSize = sizeof(SP_DEVINFO_DATA);
	while (SetupDiEnumDeviceInfo(hDI, i, &spDID))
	{
		BYTE buffer [256];
		DWORD buffer_size = sizeof(buffer);

		SetupDiGetDeviceRegistryProperty(hDI, &spDID, SPDRP_HARDWAREID, NULL, buffer, buffer_size, NULL);
		if (strstr((const char *)buffer, hardware_id))
		{
			SP_PROPCHANGE_PARAMS spPCP;
			spPCP.ClassInstallHeader.cbSize = sizeof(SP_CLASSINSTALL_HEADER);
			spPCP.ClassInstallHeader.InstallFunction = DIF_PROPERTYCHANGE;
			spPCP.Scope = state_change == DICS_ENABLE? DICS_FLAG_GLOBAL : DICS_FLAG_CONFIGSPECIFIC;
			spPCP.StateChange = state_change;
			spPCP.HwProfile = 0;

			if (SetupDiSetClassInstallParams(hDI, &spDID, &spPCP.ClassInstallHeader, sizeof(spPCP)))
			{
				BOOL result = SetupDiCallClassInstaller(DIF_PROPERTYCHANGE, hDI, &spDID);
				return result;
			}
		}
		i++;
	}
}

