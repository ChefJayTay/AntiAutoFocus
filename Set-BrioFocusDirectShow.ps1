# Set-BrioFocusDirectShow.ps1
# Uses DirectShow via C# P/Invoke to set Logitech Brio focus to Manual (Infinity).

$Source = @"
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;

namespace BrioControl
{
    public static class CameraUtils
    {
        // DirectShow GUIDs
        public static readonly Guid CLSID_SystemDeviceEnum = new Guid("62BE5D10-60EB-11d0-BD3B-00A0C911CE86");
        public static readonly Guid CLSID_VideoInputDeviceCategory = new Guid("860BB310-5D01-11d0-BD3B-00A0C911CE86");
        public static readonly Guid IID_IPropertyBag = new Guid("55272A00-42CB-11CE-8135-00AA004BB851");
        public static readonly Guid IID_IBaseFilter = new Guid("56a86895-0ad4-11ce-b03a-0020af0ba770");
        public static readonly Guid IID_IAMCameraControl = new Guid("C6E13370-30AC-11d0-A18C-00A0C9118956");

        [ComImport, Guid("62BE5D10-60EB-11d0-BD3B-00A0C911CE86")]
        public class CreateDevEnum { }

        [ComImport, Guid("55272A00-42CB-11CE-8135-00AA004BB851"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        public interface IPropertyBag
        {
            [PreserveSig]
            int Read([In, MarshalAs(UnmanagedType.LPWStr)] string propName, out object ptrVar, int errorLog);
            [PreserveSig]
            int Write([In, MarshalAs(UnmanagedType.LPWStr)] string propName, [In, MarshalAs(UnmanagedType.Struct)] ref object ptrVar);
        }

        [ComImport, Guid("29840822-5B84-11D0-BD3B-00A0C911CE86"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        public interface ICreateDevEnum
        {
            [PreserveSig]
            int CreateClassEnumerator([In] ref Guid pType, [Out] out IEnumMoniker ppEnumMoniker, [In] int dwFlags);
        }

        [ComImport, Guid("00000102-0000-0000-C000-000000000046"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        public interface IEnumMoniker
        {
            [PreserveSig]
            int Next([In] int celt, [Out, MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 0)] IMoniker[] rgelt, [Out] out int pceltFetched);
            [PreserveSig]
            int Skip([In] int celt);
            [PreserveSig]
            int Reset();
            [PreserveSig]
            int Clone([Out] out IEnumMoniker ppenum);
        }

        [ComImport, Guid("0000000f-0000-0000-C000-000000000046"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        public interface IMoniker
        {
            // IPersist
            [PreserveSig] int GetClassID(out Guid pClassID);
            // IPersistStream
            [PreserveSig] int IsDirty();
            [PreserveSig] int Load(object pStm);
            [PreserveSig] int Save(object pStm, bool fClearDirty);
            [PreserveSig] int GetSizeMax(out long pcbSize);

            // IMoniker
            [PreserveSig]
            int BindToObject([In, MarshalAs(UnmanagedType.Interface)] object pbc, [In, MarshalAs(UnmanagedType.Interface)] IMoniker pmkToLeft, [In] ref Guid riidResult, [Out, MarshalAs(UnmanagedType.Interface)] out object ppvResult);
            [PreserveSig]
            int BindToStorage([In, MarshalAs(UnmanagedType.Interface)] object pbc, [In, MarshalAs(UnmanagedType.Interface)] IMoniker pmkToLeft, [In] ref Guid riid, [Out, MarshalAs(UnmanagedType.Interface)] out object ppvObj);
        }

        [ComImport, Guid("C6E13370-30AC-11d0-A18C-00A0C9118956"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        public interface IAMCameraControl
        {
            [PreserveSig]
            int GetRange(int Property, out int pMin, out int pMax, out int pSteppingDelta, out int pDefault, out int pCapsFlags);
            [PreserveSig]
            int Set(int Property, int lValue, int Flags);
            [PreserveSig]
            int Get(int Property, out int lValue, out int Flags);
        }

        public static void SetFocus(string partialName, int focusValue)
        {
            ICreateDevEnum devEnum = (ICreateDevEnum)new CreateDevEnum();
            IEnumMoniker enumMoniker = null;
            Guid videoInputGuid = CLSID_VideoInputDeviceCategory;
            
            int hr = devEnum.CreateClassEnumerator(ref videoInputGuid, out enumMoniker, 0);
            if (hr != 0 || enumMoniker == null) return;

            IMoniker[] monikers = new IMoniker[1];
            int fetched;

            while (enumMoniker.Next(1, monikers, out fetched) == 0 && fetched == 1)
            {
                IMoniker moniker = monikers[0];
                object bagObj = null;
                Guid bagId = IID_IPropertyBag;
                
                try
                {
                    moniker.BindToStorage(null, null, ref bagId, out bagObj);
                    IPropertyBag bag = (IPropertyBag)bagObj;
                    object val;
                    int hrBag = bag.Read("FriendlyName", out val, 0);
                    if (hrBag == 0)
                    {
                        string name = (string)val;
                        if (name.Contains(partialName))
                        {
                            Console.WriteLine("Found Camera: " + name);
                            
                            object filterObj = null;
                            Guid filterId = IID_IBaseFilter;
                            moniker.BindToObject(null, null, ref filterId, out filterObj);
                            
                            IAMCameraControl camControl = filterObj as IAMCameraControl;
                            if (camControl != null)
                            {
                                int focusProp = 6; // CameraControl_Focus
                                int min, max, step, def, caps;
                                int hrRange = camControl.GetRange(focusProp, out min, out max, out step, out def, out caps);
                                if (hrRange == 0)
                                {
                                    Console.WriteLine("  Focus Range: Min=" + min + " Max=" + max + " Step=" + step + " Default=" + def + " Caps=" + caps);
                                    
                                    int curVal, curFlags;
                                    camControl.Get(focusProp, out curVal, out curFlags);
                                    Console.WriteLine("  Current Focus: Val=" + curVal + " Flags=" + curFlags);

                                    // Property 6 = Focus
                                    // Flags 2 = Manual
                                    // Ensure value is within range
                                    int targetValue = focusValue;
                                    if (targetValue < min) targetValue = min;
                                    if (targetValue > max) targetValue = max;
                                    
                                    Console.WriteLine("  Setting Focus to " + targetValue + " (Manual)...");
                                    int hrSet = camControl.Set(focusProp, targetValue, 2); 
                                    if (hrSet == 0)
                                        Console.WriteLine("  Successfully set Focus to Manual (" + targetValue + ")");
                                    else
                                        Console.WriteLine("  Failed to set Focus. HRESULT: " + hrSet);
                                }
                                else
                                {
                                    Console.WriteLine("  Failed to get Focus Range. HRESULT: " + hrRange);
                                }
                            }
                            else
                            {
                                Console.WriteLine("  IAMCameraControl interface not supported.");
                            }
                            
                            Marshal.ReleaseComObject(filterObj);
                        }
                    }
                    Marshal.ReleaseComObject(bag);
                }
                catch (Exception ex)
                {
                    Console.WriteLine("  Error processing device: " + ex.Message);
                }
                finally
                {
                    Marshal.ReleaseComObject(moniker);
                }
            }
            Marshal.ReleaseComObject(enumMoniker);
            Marshal.ReleaseComObject(devEnum);
        }
    }
}
"@

Add-Type -TypeDefinition $Source -Language CSharp

Write-Host "Attempting to set focus via DirectShow..."
[BrioControl.CameraUtils]::SetFocus("BRIO", 0)
