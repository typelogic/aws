------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                     Copyright (C) 2003-2012, AdaCore                     --
--                                                                          --
--  This is free software;  you can redistribute it  and/or modify it       --
--  under terms of the  GNU General Public License as published  by the     --
--  Free Software  Foundation;  either version 3,  or (at your option) any  --
--  later version.  This software is distributed in the hope  that it will  --
--  be useful, but WITHOUT ANY WARRANTY;  without even the implied warranty --
--  of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU     --
--  General Public License for  more details.                               --
--                                                                          --
--  You should have  received  a copy of the GNU General  Public  License   --
--  distributed  with  this  software;   see  file COPYING3.  If not, go    --
--  to http://www.gnu.org/licenses for a complete copy of the license.      --
------------------------------------------------------------------------------

--  SOAP/WSDL test

with Ada.Text_IO;

with AWS.MIME;
with AWS.Response;
with AWS.Server;
with AWS.Status;
with SOAP.Utils;

with R_Hello_Demo.Client;
with R_Hello_Demo.Server;

procedure Test_WSDL is

   use AWS;

   H_Server : Server.HTTP;

   procedure WSDL_Demo_Client is
      use Ada;
   begin
      Text_IO.Put_Line (R_Hello_Demo.Client.sayHello (Firstname => "AWS"));
   end WSDL_Demo_Client;

   function sayHello (Firstname : String) return String;

   -------------
   -- SOAP_CB --
   -------------

   function SOAP_CB is new R_Hello_Demo.Server.sayHello_CB (sayHello);

   function SOAP_Wrapper is new SOAP.Utils.SOAP_Wrapper (SOAP_CB);

   --------
   -- CB --
   --------

   function CB (Request : Status.Data) return Response.Data is
      SOAPAction : constant String := Status.SOAPAction (Request);
   begin
      if SOAPAction = "sayHello" then
         return SOAP_Wrapper (Request);
      else
         return Response.Build (MIME.Text_HTML, "<p>Not a SOAP request");
      end if;
   end CB;

   --------------
   -- sayHello --
   --------------

   function sayHello (Firstname : String) return String is
   begin
      return "Hello " & Firstname & " and welcome!";
   end sayHello;

begin
   Server.Start
     (H_Server, "WSDL Hello demo",
      CB'Unrestricted_Access,
      Port => R_Hello_Demo.Server.Port);

   WSDL_Demo_Client;

   Server.Shutdown (H_Server);
end Test_WSDL;
