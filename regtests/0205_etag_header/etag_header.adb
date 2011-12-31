------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                     Copyright (C) 2010-2012, AdaCore                     --
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

with AWS.Client;
with AWS.Headers.Set;
with AWS.Messages;
with AWS.MIME;
with AWS.Response;
with AWS.Server;
with AWS.Status;
with AWS.Utils;

with Get_Free_Port;

procedure ETag_Header is

   use Ada;
   use AWS;

   WS   : Server.HTTP;
   Port : Positive := 8274;

   --------
   -- CB --
   --------

   function CB (Request : Status.Data) return Response.Data is

      H : constant Headers.List := Status.Header (Request);

      procedure Output (Header : String);
      --  Output corresponding header value

      ------------
      -- Output --
      ------------

      procedure Output (Header : String) is
      begin
         if Headers.Exist (H, Header) then
            declare
               Value : constant String := Headers.Get (H, Header);
            begin
               Text_IO.Put_Line (Header & ": " & Value);
            end;

         else
            Text_IO.Put_Line (Header & ": NOT FOUND");
         end if;
      end Output;

   begin
      Text_IO.Put_Line (">>>>> " & Status.URI (Request));
      Output (Messages.ETag_Token);
      Text_IO.New_Line;
      return Response.Build (MIME.Text_HTML, "ok");
   end CB;

   R  : Response.Data;
   H  : Headers.List;

begin
   Get_Free_Port (Port);

   Server.Start
     (WS, "ETag Header", CB'Unrestricted_Access, Port => Port);

   Headers.Set.Add
     (H, Messages.ETag_Token, String (Messages.Create_ETag ("azerty")));

   R := AWS.Client.Get
     (URL => "http://localhost:" & Utils.Image (Port) & "/get", Headers => H);

   Headers.Set.Reset (H);

   Headers.Set.Add
     (H, Messages.ETag_Token,
      String (Messages.Create_ETag ("qwerty", Weak => True)));

   R := AWS.Client.Head
     (URL => "http://localhost:" & Utils.Image (Port) & "/head", Headers => H);

   R := AWS.Client.Post
     (URL => "http://localhost:" & Utils.Image (Port) & "/post",
      Data => "", Headers => H);

   Text_IO.Put_Line
     ("Etag Header : '"
      & Messages.ETag (Messages.Create_ETag ("mytag")) & ''');

   Server.Shutdown (WS);
   Text_IO.Put_Line ("shutdown");
end ETag_Header;
