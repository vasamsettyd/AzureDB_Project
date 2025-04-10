Watermark table
create procedure watermarktable
@lastload varchar(200)
as
begin
 begin transaction;
  update watermark_table
   set last_load = @lastload
   commit transaction;

    end;




create table watermark_table
(
last_load varchar(2000)
)

select * from watermark_table
Insert into watermark_table
values('DT00000')

select * from [dbo].[sourcecars_data] where Date_ID > 'DT00000'


select  min(Date_ID) from [dbo].[sourcecars_data]
select  max(Date_ID) from [dbo].[sourcecars_data]














select * from [dbo].[watermarktable]
select * from [dbo].[sourcecars_data]
select * from [dbo].[updatewatermarktable]