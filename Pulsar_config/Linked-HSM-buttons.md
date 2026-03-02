# Linking/unlinking HSM buttons in Pulsar

The **Digital Outputs** field in Pulsar allows you to control the **Hydraulic Service Manifolds (HSMs)**. By default, where multiple HSMs are in use, functions are combined into one button in the GUI. There may be some cases (e.g. use of soil pit actuators) where control of individual manifolds is preferred. To allow this, edit the Pulsar config file as detailed below.

Navigate to and open:
```
C:\Program Files (x86)\Servotest\Pulsar\Pulsar.exe.Config
```
Under:

```
  <system.diagnositics>
    <switches>
      ...
```
Edit the following line as needed
```
  <add name="HsmsBound" value="1" />
```
```1``` = True (Buttons combined)\
```0``` = False (Separate buttons for each HSM)
