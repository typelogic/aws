------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                     Copyright (C) 2009-2012, AdaCore                     --
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

with Ada.Text_IO;
with Ada.Exceptions;

with GNAT.MD5;

with AWS.Client;
with AWS.Digest;
with AWS.Server;
with AWS.Status;
with AWS.MIME;
with AWS.Response;
with AWS.Messages;
with AWS.Utils;

with Get_Free_Port;
with Stack_Size;

procedure Pauth is

   use GNAT;
   use Ada;
   use Ada.Text_IO;
   use AWS;

   function CB (Request : Status.Data) return Response.Data;

   task Server is
      pragma Storage_Size (Stack_Size.Value);
      entry Wait_Start;
      entry Stop;
   end Server;

   HTTP : AWS.Server.HTTP;

   Connect : Client.HTTP_Connection;

   Digest_Protected_URI : constant String := "/Digest";

   Auth_Username : constant String := "AWS";
   Auth_Password : constant String := "letmein";

   R    : Response.Data;
   Port : Natural := 1236;

   --------
   -- CB --
   --------

   function CB (Request : Status.Data) return Response.Data is
      Username    : String := AWS.Status.Authorization_Name (Request);
      Valid_Nonce : Boolean;
   begin
      Put_Line ("CB: URI        " & Status.URI (Request));
      Put_Line ("CB: SOAPAction " & Status.SOAPAction (Request));
      Valid_Nonce := Digest.Check_Nonce (Status.Authorization_Nonce (Request));

      Put_Line ("Valid_Nonce : " & Boolean'Image (Valid_Nonce));

      if Status.Check_Digest (Request, Auth_Password) then
         return AWS.Response.Build
           ("text/plain", "Digest authorization OK!");

      else
         return AWS.Response.Authenticate
           ("AWS regtest", AWS.Response.Digest, Stale => not Valid_Nonce);
      end if;
   end CB;

   ------------
   -- Server --
   ------------

   task body Server is
   begin
      Get_Free_Port (Port);

      AWS.Server.Start
        (HTTP, "Test authentication.",
         CB'Unrestricted_Access, Port => Port, Max_Connection => 3);

      accept Wait_Start;
      accept Stop;

   exception
      when E : others =>
         Put_Line ("Server Error " & Exceptions.Exception_Information (E));
   end Server;

begin
   Server.Wait_Start;

   Client.Create
     (Connection => Connect,
      Host       => "http://localhost:" & Utils.Image (Port),
      Timeouts   => Client.Timeouts
        (Connect => 5.0, Send => 5.0, Receive => 5.0));

   --  Test for digest authentication

   Client.Set_WWW_Authentication
     (Connect, Auth_Username, Auth_Password, Client.Digest);

   Client.SOAP_Post (Connect, R, "action", "data", True);
   Put_Line ("-> " & Messages.Image (Response.Status_Code (R)));

   Client.Close (Connect);

   Server.Stop;

exception
   when E : others =>
      Server.Stop;
      Put_Line ("Main Error " & Exceptions.Exception_Information (E));
end Pauth;
